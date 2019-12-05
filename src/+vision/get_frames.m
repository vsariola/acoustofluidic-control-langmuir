function imageData = get_frames(numFrames)
    import vision.*
    global vid;
                      
    vid.FramesPerTrigger = numFrames;    
        
    start(vid);    
    numAvail = vid.FramesAvailable;  
    while(numAvail<numFrames)
        numAvail = vid.FramesAvailable;
    end
    stop(vid);      
    
    imageData = getdata(vid);

