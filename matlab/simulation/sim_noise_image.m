% SIM_NOISE_IMAGE Extract noise images from simulation
%
% Usage
%    im = sim_noise_image(sim, start, num);
%
% Input
%    sim: Simulation object from `create_sim`.
%    start: First index of the images to extract.
%    num: The number of images to extract.
%
% Output
%    im: The noise simulation images from start to start+num-1.
%
% See also
%    sim_image, create_sim

% Author
%    Joakim Anden <janden@flatironinstitute.org>

function im = sim_noise_image(sim, start, num)
    precision = class(sim.vols);

    noise_filter = power_filter(sim.noise_psd, 1/2);

    im = zeros([2*sim.L*ones(1, 2) num], precision);

    rand_push();

    for s = start:start+num-1
        rand_state(sim.noise_seed + 191*s);

        im_s = randn(2*sim.L*ones(1, 2), precision);

        im(:,:,s-start+1) = im_s;
    end

    im = im_filter(im, noise_filter);
    im = im(1:sim.L,1:sim.L,:);

    rand_pop();
end
