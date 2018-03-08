%% render subcube
subcube=M(11:512,11:512,1:128);
%% set up
x = 1:512;
y = 1:512;
z = 1:128;
[x,y,z]=ndgrid(x,y,z);
TH_LOG = 12;
th = 2^TH_LOG-1;
pls = subcube;%-min(min(min(subcube)));
pls(pls>th)=th;
pls(pls<0)=0;
%% plot
slice(double(pls), 500, 1, 1:20:100);
%% format
axis off
%colorbar
shading flat
colormap jet
view(-110, 30)

%% animate
h = figure;
axis tight manual % this ensures that getframe() returns a consistent size
filename = 'testAnimated.gif';
wb = waitbar(0);
N = 128;
dt = 1/25; %1/fps
iminds = {};
cms = {};
for n = 1:N
    waitbar(n/N, wb);
    % Draw plot for y = x.^n
    x = 0:0.01:1;
    y = x.^n;
    
    slice(double(pls), 512, 512, n);
    set(gcf, 'color', 'none');
    set(gcf, 'Position', [0, 0, 1080, 1080]);
    axis off
    shading flat
    colormap jet
    view(-20, 30)
    
    drawnow 
      % Capture the plot as an image 
      frame = getframe(h); 
      im = frame2im(frame); 
      [imind,cm] = rgb2ind(im,256); 
      iminds{n} = imind;
      cms{n} = cm;
      % Write to the GIF File 
      if n == 1 
          imwrite(imind,cm,filename,'gif', 'DelayTime', dt, 'Loopcount',inf); 
      else 
          imwrite(imind,cm,filename,'gif','DelayTime', dt, 'WriteMode','append'); 
      end 
end
for n=N-1:-1:2
    imwrite(iminds{n},cms{n},filename,'gif','DelayTime', dt, 'WriteMode','append'); 
end

delete(wb)