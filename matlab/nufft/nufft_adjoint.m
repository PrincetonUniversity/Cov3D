% NUFFT_ADJOINT Apply adjoint transform according to NUFFT plan
%
% Usage
%    sig = nufft_adjoint(plan, sig_f);
%
% Input
%    plan: An NUFFT plan.
%    sig_f: A non-uniform transform of a signal.
%
% Output
%    sig: The adjoint transform of sig_f.

% Author
%    Joakim Anden <janden@flatironinstitute.org>

function sig = nufft_adjoint(plan, sig_f)
    if ~isfield(plan, 'lib_code') || ~isfield(plan, 'sz') || ...
        ~isfield(plan, 'num_pts')
        error('Input ''plan'' is not a valid NUFFT plan.');
    end

    if ~isfield(plan, 'fourier_pts')
        error('Plan has not been initialized with Fourier points.');
    end

    dims = numel(plan.sz);

    if ndims(sig_f) ~= 2 || any(size(sig_f) ~= [plan.num_pts 1])
        error('Input ''sig_f'' must be of size plan.num_pts-by-1.');
    end

    precision = class(sig_f);

    epsilon = max(plan.epsilon, eps(precision));

    if plan.lib_code == 1
        if dims == 1
            sig = anudft1(sig_f, plan.fourier_pts, plan.sz);
        elseif dims == 2
            sig = anudft2(sig_f, plan.fourier_pts, plan.sz);
        elseif dims == 3
            sig = anudft3(sig_f, plan.fourier_pts, plan.sz);
        end
    elseif plan.lib_code == 2
        sig_f = double(sig_f(:));

        % NUFFT errors if we give epsilon in single precision.
        epsilon = double(epsilon);

        if dims == 1
            sig = plan.num_pts*nufft1d1(plan.num_pts, ...
                plan.fourier_pts(1,:), ...
                sig_f, ...
                1, epsilon, plan.sz(1));
        elseif dims == 2
            sig = plan.num_pts*nufft2d1(plan.num_pts, ...
                plan.fourier_pts(1,:), ...
                plan.fourier_pts(2,:), ...
                sig_f, ...
                1, epsilon, ...
                plan.sz(1), plan.sz(2));
        elseif dims == 3
            sig = plan.num_pts*nufft3d1(plan.num_pts, ...
                plan.fourier_pts(1,:), ...
                plan.fourier_pts(2,:), ...
                plan.fourier_pts(3,:), ...
                sig_f, ...
                1, epsilon, ...
                plan.sz(1), plan.sz(2), plan.sz(3));
        end

        sig = reshape(sig, [plan.sz 1]);
    elseif plan.lib_code == 3
        if ~isfield(plan, 'nfft_plan_id')
            error('Input ''plan'' is not a valid NUFFT plan.');
        end

        sig_f = double(sig_f);
        sig_f = sig_f(:);

        if plan.num_threads ~= 0
            orig_num_threads = omp_get_max_threads();
            omp_set_num_threads(plan.num_threads);
        end

        nfft_set_f(plan.nfft_plan_id, sig_f);
        nfft_adjoint(plan.nfft_plan_id);
        sig = nfft_get_f_hat(plan.nfft_plan_id);

        if plan.num_threads ~= 0
            omp_set_num_threads(orig_num_threads);
        end

        if dims == 2
            sig = permute(reshape(sig, plan.sz), [2 1]);
        elseif dims == 3
            sig = permute(reshape(sig, plan.sz), [3 2 1]);
        end
    elseif plan.lib_code == 4
        sig_f = double(sig_f(:));

        % FINUFFT errors if we give epsilon in single precision.
        epsilon = double(epsilon);

        if plan.num_threads ~= 0
            orig_num_threads = omp_get_max_threads();
            omp_set_num_threads(plan.num_threads);
        end

        if dims == 1
            sig = finufft1d1( ...
                plan.fourier_pts(1,:), ...
                sig_f, ...
                1, epsilon, plan.sz(1));
        elseif dims == 2
            sig = finufft2d1( ...
                plan.fourier_pts(1,:), ...
                plan.fourier_pts(2,:), ...
                sig_f, ...
                1, epsilon, ...
                plan.sz(1), plan.sz(2));
        elseif dims == 3
            sig = finufft3d1( ...
                plan.fourier_pts(1,:), ...
                plan.fourier_pts(2,:), ...
                plan.fourier_pts(3,:), ...
                sig_f, ...
                1, epsilon, ...
                plan.sz(1), plan.sz(2), plan.sz(3));
        end

        if plan.num_threads ~= 0
            omp_set_num_threads(orig_num_threads);
        end

        sig = reshape(sig, [plan.sz 1]);
    end

    sig = cast(sig, precision);
end
