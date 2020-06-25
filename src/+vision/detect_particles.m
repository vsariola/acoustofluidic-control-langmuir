function p = detect_particles(img,varargin) 
% detect_particles  Detect particles from an image
%   p = detect_particles(img) find the particles from a RGB image img (HxWx3)
%   array. The returned value is a N x 2 array, where p(:,1) are the
%   x-coordinates of the particles and p(:,2) are the y-coordinates of the
%   particles. Notice that find_particles uses minmaxfilt, which needs to
%   be compiled once by running minmaxfilter_install. Optional parameters
%   (find_particles(...,'param',value)):
%
%   particle_diameter : sets the diameter of the particles sought, in pixels.
%                     Default: 8
%   blur            : width of the averaging kernel used to blur the
%                     image. Defualt: 3.
%   edge_stddev     : the standard deviation of the gaussian kernel used
%                     used to blur the edges. Default: 3
%   edge_filtersize : what is the width of the kernel used to blur the
%                     edges. Should be at least ~2x edgeblur_stddev.
%                     Default: 6
%   detection_threshold : TBW Default: 0.0005
%   color_threshold : TBW. Default: 0.8
%   target_color    : TBW Default: [0.22 0.17]
%   max_particles   : TBW Default: 1e4
%   debug           : Show all intermediate steps of the algorithm.
%                     Default: false
    import vision.*
    import third_party.min_max_filter.*

    % Default values for parameters
    def_particle_diameter = 8; % particle diameter pixels
    def_blur = 5; % what is the width of the average blur kernel, in pixels    
    def_edge_stddev = 3; % standard deviation of the gaussian kernel used to blur the edges
    def_edge_filtersize = 6; % edgeblur kernel width, in pixels, should be at least 2 x standard deviation
	def_detection_threshold = 0.0005; % 0 - 1
    def_color_threshold = 0.8; % 0 - 1
    def_target_color = [0.22 0.17]; % R/B and G/B ratios of the color   
    def_max_particles = 1e4; % maximum number of particles detected
    def_debug_detector = false; % enable to plot all the steps of the algorithm
    
    % Parse the function parameters using inputParser
    iswhole = @(x)ceil(x)==floor(x);    
    parser = inputParser;
    parser.addRequired('img',@isnumeric);    
    parser.addParameter('particle_diameter',def_particle_diameter,iswhole);    
    parser.addParameter('blur',def_blur,@isnumeric);    
    parser.addParameter('edge_stddev',def_edge_stddev,@isnumeric);    
    parser.addParameter('edge_filtersize',def_edge_filtersize,iswhole);    
    parser.addParameter('color_threshold',def_color_threshold,@isnumeric);    
    parser.addParameter('target_color',def_target_color,@isnumeric);    
    parser.addParameter('debug_detector',def_debug_detector);    
    parser.addParameter('detection_threshold',def_detection_threshold);    
    parser.addParameter('max_particles',def_max_particles,iswhole);    
    parser.KeepUnmatched = true;
    parse(parser,img,varargin{:});  
    param = parser.Results;
     
    debug(img,'Input image');
    
    % Blur the image with an average filter
    h_avg = fspecial('average',param.blur);    
    img_filt = imfilter(img,h_avg);
    debug(img_filt,'Image after averaging blur');
    
    % Convert image into a grayscale image
    img_gray = double(rgb2gray(img_filt))/255;   
    debug(img_gray,'Image after converting to grayscale');
    
    % Detect edges
    edges = double(edge(img_gray,'sobel'));
    debug(edges,'Detected edges');
    
    % Slightly blur the detected edges
    h_edge = fspecial('gaussian', param.edge_stddev, param.edge_stddev);    
    edges_blurred = conv2(edges,h_edge);
    debug(edges_blurred,'Edges after blurring');
    
    % Generate a template: how an ideal circle of the given particle size
    % would look after edge detectiong and blurring.          
    template = zeros(param.particle_diameter+1,param.particle_diameter+1);    
    t = linspace(0,2*pi);
    xind = round((cos(t)+1)*param.particle_diameter/2+1);
    yind = round((sin(t)+1)*param.particle_diameter/2+1);    
    linearInd = sub2ind(size(template), yind, xind);
    template(linearInd) = 1;    
    debug(template,'Template');
    
    % Find the cross correlation between the template and the blurred edges
    xc = xcorr2(edges_blurred,template);
    xc = xc / sqrt(sum(xc(:) .^ 2)); % Normalize the cross correlation
    debug(xc,'Normalized cross correlation');
    
    % The next goals is to find the local maxima of the cross correlation.
    % To do that, we filter the cross correlation image with a maxfilter.
    % The output of maxfilter is that each pixel has the maximum of the
    % values in its local neighborhood, the width of the neighborhood
    % given by the second parameter.
    k = round((param.particle_diameter+param.edge_filtersize+1)/2);    
    xc_filt = minmaxfilt(xc,k*2+1,'max','same');
    debug(xc_filt,'Max-filtered cross correlation');
    
    % All pixels that have xc == xc_filt are local maxima. Additionally,
    % we have a fixed threshold that the height of the peak needs to be at
    % least in order to be called a local maximum.
    ind = xc == xc_filt & xc >= param.detection_threshold;        
    [y,x] = ind2sub(size(xc),find(ind));    
    p = [x,y];
    p = round(p - ones(size(p))*(param.particle_diameter/2 + (param.edge_filtersize-1)/2));        
    valid = p(:,1) >= param.particle_diameter & p(:,1) <= size(img,2)-param.particle_diameter & p(:,2) >= param.particle_diameter & p(:,2) <= size(img,1)-param.particle_diameter;
    p = p(valid,:);  
    debug(img,'Detected peaks',p);
    
    
    % Find the color of the pixel at the center of the potential detection     
    colors = zeros(size(p,1),3);               
    for i = 1:size(p,1)
        colors(i,:) = img(p(i,2),p(i,1),:);
    end
         
    % Calculate the ratios of red to blue and green to blue
    color_ratios = colors(:,1:2) ./ (colors(:,3) * [1 1]);
    
    % Calculate the difference between ratios and target ratios
    ratio_diffs = ones(size(color_ratios,1),1) * param.target_color - color_ratios;
    
    % Absolute value of the color difference
    abs_diffs = sqrt(sum(ratio_diffs.^2,2));
    
    % Keep particles that have their color R/B and G/B ratios close enough
    % to the desired ratios. Reason for using ratios is that ratios are
    % more insensitive to variations in lighting.
    valid_colors = abs_diffs < param.color_threshold;
    p = p(valid_colors,:);  
    debug(img,'Final detection, invalid colored removed',p);
                       
    % Function for displaying intermediate steps only if debugging is 
    % enabled.
	function debug(myimg,mytitle,p)
        if parser.Results.debug_detector
            figure('position',[0.1 0.1 0.4 0.4]);
            imshow(myimg);
            title(mytitle);
            if nargin >= 3
                hold on;
                plot(p(:,1),p(:,2),'y+');
                hold off;
            end
        end       
    end
end