function init()
    global vid;

    if ~exist('vid','var') || isempty(vid) || ~isvalid(vid)
        imaqreset;
        vid = videoinput('gentl',1,'RGB8');                            
        vid.ROIPosition = [0 0 2064 1544];
        img = getsnapshot(vid);
        imshow(img);    
        title('Click on the top left corner');
        tl = ginput(1);
        title('Click on the bottom right corner');
        br = ginput(1);

        s = [1014 870];
        tlr = round((tl+br-s)/4)*2;        
        vid.ROIPosition = [tlr s];        
        fprintf('Video initialized: %s\n',vid.Name);
    end      