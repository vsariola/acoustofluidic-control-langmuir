function ret = tracker(startpos,varargin)
    default_matchdist = 1; % mm

    parser = inputParser;      
    parser.addRequired('startpos',@(x)isnumeric(x) && size(x,2) == 2);
    parser.addParameter('matchdist',default_matchdist,@isnumeric);        
    parser.KeepUnmatched = true;
    parse(parser,startpos,varargin{:});    
    r = parser.Results;
    logging.message('%s\n%s',mfilename,third_party.struct2str(r));  
     
    ret = struct('update_pos',@update_pos,'get_pos',@get_pos);
    
    cur_pos = r.startpos;
    logging.log('tracker_pos',cur_pos);
    
    %----------------
    % Inner functions
    %----------------
    function update_pos(detected_pos)
        distmat = pdist2(cur_pos,detected_pos);
        for i = 1:size(cur_pos,1)
            [min_val,idx] = min(distmat(:));
            [row,col] = ind2sub(size(distmat),idx);
            if min_val > r.matchdist
                logging.message('Warning: lost tracking of a particle, position(s) not updated.');
                break;
            end
            cur_pos(row,:) = detected_pos(col,:);
            distmat(row,:) = inf;
        end
        logging.log('tracker_pos',cur_pos);        
    end

    function ret = get_pos()
        ret = cur_pos;
    end
end