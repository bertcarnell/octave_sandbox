% need package io for reading excel
% only have to do with once
% pkg install -forge io

pkg load io;

%###############################################################################

[X, Xheader] = xlsread('C:\Users\drda2\OneDrive\Research\ADHESION TEST\12212018\SO1-30_12212018.xlsx');
position = X(:,1);
force = X(:,2);

figure('Name', 'Position v Forve');
plot(position, force, "ob")
set(gca, "fontsize", 24);

% plot the raw data with blue points ("ob")
%figure(1, "position", [1,1,1800,1200]);
plot(position, force, "ob");
xlabel("Position (mm)");
ylabel("Force (N)");
set(gca, "fontsize", 24);

% plot position vs time and force vs time
%figure(2, "position", [1,1,1800,1200]);
plot(time, position, "ob");
xlabel("Time");
ylabel("Position (mm)");
set(gca, "fontsize", 24);

%figure(3, "position", [1,1,1800,1200]);
plot(time, force, "ob");
xlabel("Time");
ylabel("Force (N)");
set(gca, "fontsize", 24);

% recognize the different parts of the curves
% use the position curve since it is less noisy and is set by the machine
section = repmat(char(0),size(X,1),1);
current = "a";
idx_depress_to_hold = 0;
idx_hold_to_pull = 0;
idx_pull_to_reset = 0;
for i=1:length(section)
  if i == 1
    section(i) = "a";
    disp("start");
  elseif position(i) > position(i-1) && strcmp(current, "a")
    section(i) = "a";
  elseif position(i) == position(i-1) && strcmp(current, "a")
    current = "b";
    section(i) = "b";
    idx_depress_to_hold = i;
    disp("Switch from depress to hold");
  elseif position(i) == position(i-1) && strcmp(current, "b")
    section(i) = "b";
  elseif position(i) < position(i-1) && strcmp(current, "b")
    current = "c";
    section(i) = "c";
    idx_hold_to_pull = i;
    disp("switch from hold to pull");
  elseif position(i) < position(i-1) && strcmp(current, "c")
    section(i) = "c";
  elseif position(i) > position(i-1) && strcmp(current, "c")
    current = "d";
    section(i) = "d";
    idx_pull_to_reset = i;
    disp("switch from pull to reset");
  elseif position(i) > position(i-1) && strcmp(current, "d")
    section(i) = "d";
  end
end

% set the zero force to the mean of the reset region
zero_force = mean(force(idx_pull_to_reset:length(force)));
zero_force_std = std(force(idx_pull_to_reset:length(force)));

%spline of depress
position_a = position(idx_depress_to_hold);
position_b = position(1);
% find all points where position is between position_a and position_b and force is less that the zero line
idx = position < position_a  & position > position_b;
position_clipped_a = position(idx);
force_clipped_a = force(idx);
spline_force_a = csaps(position_clipped_a, force_clipped_a, 0.5);
% predict the splines
spline_predict_force_a = ppval(spline_force_a, position_clipped_a);

%spline of hold
position_a = position(idx_hold_to_pull);
position_b = position(idx_depress_to_hold);
% find all points where position is between position_a and position_b and force is less that the zero line
idx = position < position_a  & position > position_b;
position_clipped_b = position(idx);
force_clipped_b = force(idx);
spline_force_b = csaps(position_clipped_b, force_clipped_b, 0.5);
% predict the splines
spline_predict_force_b = ppval(spline_force_b, position_clipped_b);

%spline of pull
position_a = position(idx_pull_to_reset);
position_b = min(90.0, position(idx_hold_to_pull));
zero_force_trim = zero_force - 3*zero_force_std;
% find all points where position is between position_a and position_b and force is less that the zero line
idx = position > position_a  & position < position_b & force < zero_force_trim;
position_clipped_c = position(idx);
force_clipped_c = force(idx);
spline_force_c = csaps(position_clipped_c, force_clipped_c, 0.5);
% predict the splines
spline_predict_force_c = ppval(spline_force_c, position_clipped_c);

%figure(5, "position", [1,1,1800,1200]);
% plot the data with blue circles ("ob") and the spline with red lines ("-r")
position_clipped = [position_clipped_a; position_clipped_b; position_clipped_c ];
force_clipped = [force_clipped_a; force_clipped_b; force_clipped_c];
spline_predict_force = [spline_predict_force_a; spline_predict_force_b; spline_predict_force_c];
plot(position_clipped, force_clipped, "ob", position_clipped, spline_predict_force, "-r");
xlabel("Position (mm)");
ylabel("Force (N)");
set(gca, "fontsize", 24);

work = trapz(position_clipped_c, spline_predict_force_c - zero_force);
work
