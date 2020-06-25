function p = detect_cells(img,varargin) 
% detect_cells Detect cells from an image
%   p = detect_cells(img) find the cells from a RGB image img (HxWx3)
%   array. The returned value is a N x 2 array, where p(:,1) are the
%   x-coordinates of the cells and p(:,2) are the y-coordinates of the
%   cells.
%
%   blur_highpass   : The high cut off filter sigma, should ~ the largest
%                     cell radius to detect, in pixels
%                     Default: 30
%   blur_lowpass    : The low cut off filter sigma, should ~ the smallest
%                     cell radius to detect, in pixels
%                     Default: 3
%   opening         : The disk radius when opening the black and white
%                     image. Should be ~ the smallest cell radius to detect
%                     Default: 10
%   debug_detector  : Show all intermediate steps of the algorithm.
%                     Default: false

    % Default values for parameters    
    def_debug_detector = false; % enable to plot all the steps of the algorithm
    def_blur_highpass = 30; % ~ upper limit of the cell radius detected
    def_blur_lowpass = 3; % ~ lower limit of the cell radius detected
    def_opening = 10; % ~ lower limit of the cell radius detected
    
    % Parse the function parameters using inputParser  
    parser = inputParser;
    parser.addRequired('img',@isnumeric);        
    parser.addParameter('debug_detector',def_debug_detector);      
    parser.addParameter('blur_highpass',def_blur_highpass);          
    parser.addParameter('blur_lowpass',def_blur_lowpass);          
    parser.addParameter('opening',def_opening);          
    parser.KeepUnmatched = true;
    parse(parser,img,varargin{:});  
    param = parser.Results;
        
    % Show the original image when debugging is enabled
    debug(img,'Original image');
  
    % Switch to using doubles, as we will high pass filter soon
    gray = rgb2gray(img);
    
    % High pass filter by subtracting the lowpass from the original
    highpass_filtered = gray - imgaussfilt(gray,param.blur_highpass);
    debug(highpass_filtered,'High pass filtered');
    
    % Equalize histogram
    equalized = histeq(highpass_filtered);    
    debug(equalized,'Histogram equalized image');
    
    % Low pass the image 
    bandpass = imgaussfilt(equalized,param.blur_lowpass);
    debug(bandpass,'Band pass filtered image');

    % Convert to black and white
    bw = imbinarize(bandpass, 'adaptive');
    debug(bw,'Black and white');
    
    % Open
    opened = imopen(bw,strel('disk',param.opening,4));
    debug(opened,'Opened');
    
    % Clear white pixels near the borders of the image
    bw_no_border = imclearborder(opened,4);
    debug(bw_no_border, 'Border cleared');

    % Find the centers of the cells
    s = regionprops(bw_no_border,'centroid');    
    p = reshape(struct2array(s), 2, [])';
    
    % Debug by showing original image and detected cells
    debug(img,'Original image and detected cells',p);
    
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