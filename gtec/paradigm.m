function [sys,x0,str,ts] = paradigm(t,x,u,flag,task)

persistent fig wavelist GiveInstr TrialBegin TrialDuration TrialEnd ToneBegin ToneEnd RandomInterval TrialCount

switch flag
    case 0
        TrialCount=2;
        GiveInstr=1;
        TrialBegin=5;
        TrialDuration = 4;
        ToneBegin=TrialBegin;
        ToneEnd=ToneBegin+0.25;
        TrialEnd=TrialBegin+TrialDuration;
        RandomInterval=[0 2.5];

        sizes = simsizes;
        sizes.NumContStates  = 0;
        sizes.NumDiscStates  = 0;
        sizes.NumOutputs     = 0;  % dynamically sized
        sizes.NumInputs      = -1;  % dynamically sized
        sizes.DirFeedthrough = 0;   % has direct feedthrough
        sizes.NumSampleTimes = 1;

        sys = simsizes(sizes);
        str = [];
        x0  = [];
        ts  = [-1 0];   % inherited sample time

        set_param('Imagery/BCI System/Gain','Gain','0');
        wavelist = loadwav;

    case 2

        if t == 0
            %initialize the figure for use with this simulation
            animinit('BCI Paradigm');
            [flag,fig]=figflag('BCI Paradigm');
            pos=get(0,'ScreenSize');
            set(fig,'Visible','off');
            set(fig,'Position',[pos(1) pos(2) pos(3)/2 pos(4)/2],'MenuBar','none');
            movegui(fig,'center');
            axis([-1 1 -1 1]);
            axis('off');
            hold on;

            handles.newtrial=1;
            handles.trialnum=0;
            handles.part0=0;
            handles.part1=0;
            handles.part2=0;
            handles.part3=0;
            handles.part4=0;
            handles.part5=0;
            handles.part6=0;
            handles.part7=0;

            handles.line1=line([0 0], [0.5 -0.5],'Visible','off','EraseMode','Background');
            handles.line2=line([-0.5 0.5], [0 0],'Visible','off','EraseMode','Background');
            handles.line3=line([-0.5 -0.45],[0 0.025],'EraseMode','Background','Visible','off','LineWidth',3,'Color','r');
            handles.line4=line([-0.5 -0.45],[0 -0.025],'EraseMode','Background','Visible','off','LineWidth',3,'Color','r');
            handles.line5=line([0.5 0.45],[0 0.025],'EraseMode','Background','Visible','off','LineWidth',3,'Color','r');
            handles.line6=line([0.5 0.45],[0 -0.025],'EraseMode','Background','Visible','off','LineWidth',3,'Color','r');
            handles.line7=line([-0.5 0], [0 0], 'EraseMode','Background','Visible','off','LineWidth',3,'Color','r');
            handles.line8=line([0 0.5], [0 0], 'EraseMode','Background','Visible','off','LineWidth',3,'Color','r');
            handles.bargraph=plot([0 0],[0 0], 'LineWidth',5,'EraseMode','Background','Visible','off','Color','b');
            handles.text=text(0,0.8,sprintf('%.2f seconds. Trial number %d.',t,handles.trialnum) ,'Visible','on','EraseMode','Background');

            set(gca,'UserData',handles);
            set(fig,'Visible','on');
        end

        if any(get(0,'Children')==fig) && strcmp(get(fig,'Name'),'BCI Paradigm')

            set(0,'currentfigure',fig);
            handles=get(gca,'UserData');

            if handles.part7==0

                if handles.newtrial==1
                    handles.trialnum=handles.trialnum+1;
                    if handles.trialnum == 2
                        TrialBegin=0;
                        TrialEnd = TrialBegin + TrialDuration;
                    end
                    handles.newtrial=0;
                    handles.randomdelay=(rand*(RandomInterval(2)-RandomInterval(1)))+RandomInterval(1);
                    handles.starttime=t;
                end

                if t >= handles.starttime+GiveInstr && handles.part0==0
                    if task == 1
                        wavplay(wavelist.right_hand{1},wavelist.right_hand{2});
                    elseif task == 2
                        wavplay(wavelist.both_feet{1},wavelist.both_feet{2});
                    end
                    handles.part0=1;
                end

                if t >= handles.starttime+TrialBegin && handles.part1==0
                    %set cross visible on
                    set(handles.line1,'Visible','on');
                    set(handles.line2,'Visible','on');
                    drawnow;
                    if task==1
                        set_param('Imagery/BCI System/Gain','Gain','1');
                    elseif task == 2
                        set_param('Imagery/BCI System/Gain','Gain','2');
                    end
                    wavplay(wavelist.beep{1}, wavelist.beep{2});
                    handles.part1=1;
                end

                if (t >=handles.starttime+ToneEnd)&&(handles.part4==0)
                    set_param('Imagery/BCI System/Gain','Gain','0');
                    handles.part4=1;
                end;


                if (t >=handles.starttime+TrialEnd)&&(handles.part6==0)
                    %                 if paradigm==2
                    %                     set(handles.bargraph,'Xdata',[0 0],'Ydata',[0 0],'Visible','off');
                    %                 else

                    set(handles.line1,'Visible','off');
                    set(handles.line2,'Visible','off');
                    %                 end
                    handles.part3=1;
                    handles.part6=1;
                    drawnow;
                end;

                if t >=handles.starttime+TrialEnd+handles.randomdelay
                    handles.newtrial=1;
                    handles.part1=0;
                    handles.part2=0;
                    handles.part3=0;
                    handles.part4=0;
                    handles.part5=0;
                    handles.part6=0;
                    if handles.trialnum==TrialCount
                        handles.part7=1;
                        wavplay(wavelist.relax{1},wavelist.relax{2});
                    end
                end
                set(handles.text, 'String', sprintf('%02d:%02d:%02d Trial number %d.',floor(t/3600), ...
                    floor(mod(t,3600)/60), floor(mod(mod(t,3600),60)), handles.trialnum));
            end
            set(gca,'UserData',handles);
        end
        sys = [];

    case 9
        h=findobj('Name','BCI Paradigm');
        close(h);
end

end

function wavelist = loadwav
filepath='audio/';
filelist = {
    'beep'
    'right_hand'
    'both_feet'
    'relax'
    };

wavelist = struct();
for i=1:length(filelist)
    [wave fs] = wavread([filepath filelist{i}]);
    wavelist.(filelist{i}) = {wave, fs};
end

end