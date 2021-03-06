% CONJ_GRAD_MEAN Solve for mean volume using conjugate gradient method
%
% Usage
%    mean_est_coeff = conj_grad_mean(mean_kernel_f, mean_b_coeff, basis, ...
%       precond_kernel_f, mean_est_opt);
%
% Input
%    mean_kernel_f: The non-centered Fourier transform of the projection-
%       backprojection operator obtained from `src_mean_kernel`.
%    mean_b_coeff: An column vector containing the backprojected images
%       obtained from `src_mean_backward`, represented as coefficients in a
%       basis.
%    basis: The basis object used for representing the volumes.
%    precond_kernel_f: If not empty, the Fourier transform of a kernel that is
%       used to precondition the projection-backprojection operator (default
%       empty).
%    mean_est_opt: A struct containing the fields:
%          - 'regularizer': The regularizer parameter for the least-squares
%             problem. This is a positive number that determines how much
%             the least-squares solution is to be regularized (default 0).
%       The struct is also passed on to the `conj_grad` function, so any
%       options to that function should be passed here.
% Output
%    mean_est_coeff: A vector of length `basis.count` containing the basis
%       coefficients of the least-squares estimate obtained by solving the
%       equation (A + lambda I)*x = b, where A is the linear mapping
%       represented by convolving with `mean_kernel_f`, lambda is the regular-
%       ization parameter `mean_est_opt.regularizer`, and b is the sum of
%       backprojected images `mean_b_coeff`, expressed in `basis`. The equa-
%       tion is solved using the preconditioned conjugate gradient method
%       implemented by `conj_grad`.
%    cg_info: A structure containing information about the conjugate gradient
%       method, such as residuals, objectives, etc. See the documentation of
%       `conj_grad` for more details.

% Author
%    Joakim Anden <janden@flatironinstitute.org>

function [mean_est_coeff, cg_info] = conj_grad_mean(mean_kernel_f, ...
    mean_b_coeff, basis, precond_kernel_f, mean_est_opt)

    if nargin < 4
        precond_kernel_f = [];
    end

    if nargin < 5 || isempty(mean_est_opt)
        mean_est_opt = struct();
    end

    mean_est_opt = fill_struct(mean_est_opt, ...
        'regularizer', 0);

    if ndims(mean_b_coeff) ~= 2 || size(mean_b_coeff, 2) ~= 1
        error('Input `mean_b_coeff` must be a column vector.');
    end

    if ~is_basis(basis) || any(basis.count ~= size(mean_b_coeff, 1))
        error(['Input `basis` must be a basis object compatible with ' ...
            '`mean_b_coeff`.']);
    end

    if mean_est_opt.regularizer > 0
        mean_kernel_f = mean_kernel_f + ...
            mean_est_opt.regularizer*ones(size(mean_kernel_f));

        if ~isempty(precond_kernel_f)
            precond_kernel_f = precond_kernel_f + ...
                mean_est_opt.regularizer*ones(size(precond_kernel_f));
        end
    end

    kernel_fun = @(vol_coeff)( ...
        apply_mean_kernel(vol_coeff, mean_kernel_f, basis, mean_est_opt));

    if ~isempty(precond_kernel_f)
        precond_fun = @(vol_coeff)( ...
            apply_mean_kernel(vol_coeff, 1./precond_kernel_f, basis, ...
            mean_est_opt));

        mean_est_opt.preconditioner = precond_fun;
    end

    [mean_est_coeff, ~, cg_info] = ...
        conj_grad(kernel_fun, mean_b_coeff, mean_est_opt);
end
