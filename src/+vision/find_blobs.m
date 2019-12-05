 function ret = find_blobs(frame,visualize,threshold,max_particles)   
    import vision.*
    import third_party.min_max_filter.*
    
     DIAM = 8;
    EDGEBLUR = 3;
    EDGEBLUR_FILTSIZE = 6; 
    COLOR_THRESHOLD = 0.6;
    DESIRED_COLOR = [0.22 0.17]; % R/B and G/B of the color we are looking 
 
    if nargin < 2
        visualize = nargout < 1;   
    end
    
    if nargin < 3
        threshold = 0.0005;
    end
    
    if nargin < 4
        max_particles = 10000;
    end          
    hsize=5;

    h=fspecial('average',hsize);

    h = fspecial('average',hsize);    
    frame=imfilter(frame,h);
    blanksize = round((DIAM+EDGEBLUR_FILTSIZE+1)/2);
              
    gf = double(rgb2gray(frame))/255;                  
          
    edges = double(edge(gf,'sobel'));    
    h = fspecial('gaussian', EDGEBLUR_FILTSIZE, EDGEBLUR);    
    convolutedEdges = conv2(edges,h);
%     imshow(convolutedEdges)
%     imshow(convolutedEdges)
    t = linspace(0,2*pi);
    template = zeros(DIAM+1,DIAM+1);    
    xind = round((cos(t)+1)*DIAM/2+1);
    yind = round((sin(t)+1)*DIAM/2+1);    
    linearInd = sub2ind(size(template), yind, xind);
    template(linearInd) = 1;    
    
    xc = xcorr2(convolutedEdges,template);
    xc = xc / sqrt(sum(xc(:) .^ 2));
                
    sz = size(xc);
    ret = zeros(max_particles,2);
    C = zeros(max_particles,3);
    
    xcfilt = minmaxfilt(xc,blanksize*2+1,'max','same');
    
    ind = xc == xcfilt & xc >= threshold;
    [xx,yy] = meshgrid(round((1:size(xc,2))-DIAM/2-(EDGEBLUR_FILTSIZE-1)/2),...
                       round((1:size(xc,1))-DIAM/2-(EDGEBLUR_FILTSIZE-1)/2));
	x = max(min(xx(ind),size(frame,2)),1);
    y = max(min(yy(ind),size(frame,1)),1);
    ret = [x y];    
    N = size(ret,1);
    C = zeros(N,3);
    for i = 1:size(ret)
        C(i,:) = frame(ret(i,2),ret(i,1),:);
    end
         
     % normalize with blue to get rid of luminosity
     Cn = C(:,1:2) ./ (C(:,3) * [1 1]);
     % medCn are the color parameters of a median particle        
     % DESIRED_COLOR could be chosen as median(Cn);
     relC = ones(size(Cn,1),1) * DESIRED_COLOR - Cn;
     distC = sqrt(sum(relC.^2,2));
     % keep particle that roughly match the color of the median particle    
     ind = distC < COLOR_THRESHOLD;
     ret = ret(ind,:);    
    
    if visualize
        imshow(frame);
        hold on;
        plot(ret(:,1),ret(:,2),'r.');
        hold off;
    end                    
 end