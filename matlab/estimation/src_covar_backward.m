% SRC_COVAR_BACKWARD Apply adjoint covariance mapping to source
%
% Usage
%    covar_b = src_covar_backward(src, mean_vol, noise_var, covar_est_opt);
%
% Input
%    src: A source structure containing the images and imaging parameters.
%       This is typically obtained from `star_to_src` or `sim_to_src`.
%    mean_vol: The (estimated) mean volume of the source. This can be estimated
%       using `estimate_mean`.
%    noise_var: The variance of the noise.
%    covar_est_opt: A struct containing the fields:
%          - 'precision': The precision of the kernel. Either 'double' or
%             'single' (default).
%          - 'batch_size': The size of the batches in which to compute the
%             kernel (default 512).
%
% Output
%    covar_b: The sum of the outer products of the mean-subtracted images in
%       `src`, corrected by the expected noise contribution.

% Author
%    Joakim Anden <janden@flatironinstitute.org>

function covar_b = src_covar_backward(src, mean_vol, noise_var, ...
    covar_est_opt)

    if nargin < 4 || isempty(covar_est_opt)
        covar_est_opt = struct();
    end

    covar_est_opt = fill_struct(covar_est_opt, ...
        'precision', 'single', ...
        'batch_size', 512);

    covar_b = zeros(src.L*ones(1, 3), covar_est_opt.precision);

    for batch = 1:ceil(src.n/covar_est_opt.batch_size)
        batch_s = (batch-1)*covar_est_opt.batch_size+1;
        batch_n = min(batch*covar_est_opt.batch_size, src.n)-batch_s+1;

        im = src_image(src, batch_s, batch_n);

        im_centered = im - vol_forward(src, mean_vol, batch_s, batch_n);

        im_centered_b = zeros([src.L*ones(1, 3) batch_n], covar_est_opt.precision);

        for s = 1:batch_n
            im_centered_b(:,:,:,s) = ...
                im_backward(src, im_centered(:,:,s), batch_s+s-1);
        end

        im_centered_b = vol_to_vec(im_centered_b);

        covar_b = covar_b + 1/src.n*vecmat_to_volmat(im_centered_b*im_centered_b');
    end

    mean_kernel_f = src_mean_kernel(src, covar_est_opt);

    covar_b_noise = noise_var*kernel_to_toeplitz(mean_kernel_f);

    covar_b = covar_b - covar_b_noise;
end