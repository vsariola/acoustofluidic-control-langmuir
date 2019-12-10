function ret = real_chip(model,varargin)	
    default_draw = false;

    parser = inputParser;    
    parser.addRequired('model',@isstruct);                
    parser.addParameter('duration',0.5);        
    parser.addParameter('um_per_pixel',6.9);            
    parser.addParameter('draw',default_draw);           
    parser.KeepUnmatched = true;
    parse(parser,model,varargin{:});    
    r = parser.Results;     
    logging.message('%s\n%s',mfilename,third_party.struct2str(r));     
            
    vision.init();    
    initialize_wavegenerator();                    
    
    if r.draw
        figure;
        h_img = image(vision.get_frames(1));
        hold on;
        h_plot = plot(0,0,'yx');
    end
                
    function ret = get_pos()
        % Randomly permutate and drop particle positions, to simulate
        % a real situation that the machine vision does not always return
        % the particles in same order and might not detect them
        img = vision.get_frames(1);
        ret = vision.find_blobs(img);
        ret = ret * r.um_per_pixel / 1000; % in mm
        logging.log('chip_getpos',ret,'cell');
        if r.draw
            h_img.CData = img;            
            h_plot.XData = ret(:,1);
            h_plot.YData = ret(:,2);
        end
    end

    function output(n)       
        logging.log('chip_output',n);        
        amp = model.amp(n);
        freq = model.freq(n);        
        logging.log('chip_amp',amp);        
        logging.log('chip_freq',freq);                
        play_wave(amp,freq);
        pause(r.duration);
        play_wave(0);
    end

    ret = struct('get_pos',@get_pos,'output',@output,'numfreq',model.numfreq);
end

function play_wave(amplitude,frequency,signaltype)  
    wg = initialize_wavegenerator;

    MAX_AMPLITUDE = 0.35; % keep it small so we don't accidently fry the
    % piezo (e.g. when there's no DC offset), or even worse, fry the
    % amplifier, which can at absolute max. take 1 V RMS. Note that 0.3
    % is potentially already over the rated voltage of the piezo without
    % DC-offset 
    CHANNEL_NAME = '0';
    
    if nargin < 1
        amplitude = 0.01;
    end
    
    if nargin < 2
        frequency = 50e3;
    end
   
    % 1 = sine
    % 2 = square
    % 3 = triangle 
    % 4 = ramp up
    % 5 = ramp down 
    if nargin < 3
        signaltype = 1;
    end        
    
    if (amplitude > MAX_AMPLITUDE)
        error('Amplitude should be <= %g (is: %g)',MAX_AMPLITUDE,amplitude);
    end
    
    if (amplitude < 0)
        error('Amplitude should be >= 0 (is: %g)',amplitude);
    end
    
    if amplitude == 0
        invoke(wg.Configuration,'configureoutputenabled', CHANNEL_NAME, 0);
    else
        invoke(wg.Waveformcontrol,'abortgeneration');
        invoke(wg.Configurationfunctionsstandardfunctionoutput,'configurestandardwaveform',CHANNEL_NAME, signaltype, amplitude, 0, frequency, 0);
        invoke(wg.Waveformcontrol,'initiategeneration');            
        invoke(wg.Configuration,'configureoutputenabled', CHANNEL_NAME, 1);
    end    
end

function ret = initialize_wavegenerator
    global wg;

    if ~exist('wg','var') || isempty(wg) || ~isvalid(wg)
        resourceID = 'Dev2';
        NIFGEN_VAL_OUTPUT_FUNC = 0; 

        driverInfo = instrhwinfo ('vxipnp','niFgen');
        disp(driverInfo);            
        wg = icdevice('niFgen',resourceID,'optionstring','DriverSetup=Model:5412');    
        connect(wg);
        invoke(wg.Configuration,'configureoutputmode',NIFGEN_VAL_OUTPUT_FUNC);
    end

    ret = wg;
end