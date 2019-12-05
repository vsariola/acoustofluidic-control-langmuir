function ret = pathfollow_task(varargin)
    default_paths = {};
    default_maxsegment = Inf;
    default_minsegment = -Inf;
    default_waypointtol = 0.1;
    default_tracker = [];
    default_draw = false;
    default_first_detection = [];

    parser = inputParser;
    parser.addParameter('first_detection',default_first_detection, ...
        @(x) isempty(x) || isnumeric(x) && size(x,2) == 2);    
    parser.addParameter('paths',default_paths, ...
        @(x) iscell(x) || (isnumeric(x) && mod(size(x,2),2) == 0));    
    parser.addParameter('tracker',default_tracker, ... 
        @(x) isstruct(x) || isempty(x));              
    parser.addParameter('maxsegment',default_maxsegment);        
    parser.addParameter('minsegment',default_minsegment); 
    parser.addParameter('waypointtol',default_waypointtol);            
    parser.addParameter('draw',default_draw);           
    parser.KeepUnmatched = true;
    parse(parser,varargin{:});
    r = parser.Results;
    logging.message('%s\n%s',mfilename,third_party.struct2str(parser.Results));
    
    if isempty(r.paths)
        paths = {[1,1]};
    elseif isnumeric(r.paths)
        paths = cell(1,size(r.paths,2)/2);
        for i = 1:2:size(r.paths,2)
            paths{i} = r.paths(:,i:i+1);           
        end
    else
        paths = r.paths;
    end        
    
    first_target = cell2mat(arrayfun(@(i)paths{i}(1,:),1:length(paths), ...
        'UniformOutput',false)');
    if isempty(r.tracker)
        if isempty(r.first_detection)
            startpos = first_target;
        else
            f = figure;
            plot(r.first_detection(:,1),r.first_detection(:,2),'k.');
            hold on;
            plot(first_target(:,1),first_target(:,2),'bx');
            arrayfun(@(x,y,i)text(x,y,sprintf('Target %d',i)), ...
                first_target(:,1),first_target(:,2),1:size(first_target,1));
            set(gca,'YDir','reverse');
            startpos = zeros(length(paths),2);
            for i = 1:length(paths)
                title('Click on the first particle');
                g = ginput(1);
                startpos(i,:) = g;            
            end        
            close(f);
        end
        trck = tracker(startpos);
    else
        trck = parser.Results.tracker;
    end
    
    for i = 1:length(paths)
        logging.log('orig_paths',paths{i},'cell');
        paths{i} = space_evenly(paths{i});
        logging.log('paths',paths{i},'cell');
    end
        
    progress = ones(1,length(paths));    
    logging.log('path_progress',progress);
    done = zeros(1,length(paths));    
    logging.log('path_done',done);    
    
    if r.draw   
        figure;
        ax = axes;        
        for i = 1:length(paths)
            plot(ax,paths{i}(:,1),paths{i}(:,2),'r.');  
            hold on;
            plot(ax,paths{i}(1,1),paths{i}(1,2),'bx'); 
        end       
        set(ax,'YDir','reverse');
    end   
    
    ret = struct('update_pos',@update_pos,'update_progress',@update_progress,'get_pos',@get_pos,'get_cost',@get_cost,'is_completed',@is_completed);
            
    %-----------------
    % Member functions
    %-----------------  
    function update_pos(all_positions)       
        trck.update_pos(all_positions);        
    end

    function update_progress()
        positions = trck.get_pos();     
        if r.draw                                
            plot(ax,positions(:,1),positions(:,2),'k.');
        end           
        for j = 1:length(paths)          
            while progress(j) < length(paths{j}) && ...
                  dist(paths{j}(progress(j),:),positions(j,:)) < r.waypointtol
                % advance waypoints until we have reached the last waypoint
                progress(j) = progress(j) + 1;                
                if r.draw
                   plot(ax,paths{j}(progress(j),1),paths{j}(progress(j),2),'bx'); 
                end
            end         
            % If we are currently targeting last waypoint AND
            % we have reached the last waypoint, then this particle is
            % done.
            done(j) = progress(j) == length(paths{j}) && ...
               dist(paths{j}(progress(j),:),positions(j,:)) < r.waypointtol;            
        end
        logging.log('path_progress',progress);               
    end

    function ret = get_pos()
        ret = trck.get_pos();
    end

    function ret = get_cost(positions)
        ret = 0;
        for j = 1:length(paths)
            ret = ret + dist(paths{j}(progress(j),:),positions(j,:));
        end
    end

    function ret = is_completed()        
        ret = all(done);
    end

    %------------------
    % Private functions
    %------------------
    function ret = dist(p1,p2)
        ret = sqrt(sum((p1-p2).^2,2));
    end

    function ret = space_evenly(path)
        if isempty(path)
            ret = [];
            return;
        end
        curpoint = path(1,:);
        ret = curpoint;          
        for j = 2:size(path,1)
            newpoint = path(j,:);
            segment_delta = newpoint - curpoint;
            segment_len = sqrt(sum(segment_delta .^ 2,2));
            if segment_len < r.minsegment && j < size(path,1)
                continue;
            end
            if segment_len > r.maxsegment
                numsegments = ceil(segment_len / r.maxsegment);
            else
                numsegments = 1;
            end
            for k = 1:numsegments
                ret = [ret;curpoint+segment_delta*k/numsegments];
            end
            curpoint = newpoint;
        end
    end
end