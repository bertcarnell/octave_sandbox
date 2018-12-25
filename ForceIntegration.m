# need package io for reading excel
# only have to do with once
# pkg install -forge io

pkg load io;

################################################################################

[X, Xheader] = xlsread('SY1-30_12212018.xlsx');
position = X(:,1);
force = X(:,2);

figure(1, "position", [1,1,1800,1200]);
plot(position, force, "ob")
set(gca, "fontsize", 24);

################################################################################

[X, Xheader] = xlsread('SY1-50_12212018.xlsx');
position = X(:,1);
force = X(:,2);
time = 1:rows(X);

# plot the raw data with blue points ("ob")
figure(1, "position", [1,1,1800,1200]);
plot(position, force, "ob");
xlabel("Position (mm)");
ylabel("Force (N)");
set(gca, "fontsize", 24);

# plot position vs time and force vs time
figure(2, "position", [1,1,1800,1200]);
plot(time, position, "ob");
xlabel("Time");
ylabel("Position (mm)");
set(gca, "fontsize", 24);

figure(3, "position", [1,1,1800,1200]);
plot(time, force, "ob");
xlabel("Time");
ylabel("Force (N)");
set(gca, "fontsize", 24);

# method1 - integrate force and zero curves using pre-set points
position_a = 89.45;
position_b = 90.0;
zero_force = -0.0610;
zero_force_trim = -0.0615;
max_force = min(force);
# find all points where position is between position_a and position_b and force is less that the zero line
idx = position > position_a  & position < position_b & force < zero_force_trim;
position_clipped = position(idx);
force_clipped = force(idx);

figure(4, "position", [1,1,1800,1200]);
plot(position_clipped, force_clipped, "ob");
xlabel("Position (mm)");
ylabel("Force (N)");
set(gca, "fontsize", 24);

work = trapz(position_clipped, force_clipped - zero_force);
work # N mm

# splinefitting 
# breaks is the places where the splines are fit together
# linpace fills the space with a certain number of points
breaks = linspace(position_a, position_b, 100);
spline_force = splinefit(position_clipped, force_clipped, breaks, 
    "order", 2, "periodic", true);
# predict the splines
spline_predict_force = ppval(spline_force, position_clipped);

figure(5, "position", [1,1,1800,1200]);
# plot the data with blue circles ("ob") and the spline with red lines ("-r")
plot(position_clipped, force_clipped, "ob", 
     position_clipped, spline_predict_force, "-r");
xlabel("Position (mm)");
ylabel("Force (N)");
set(gca, "fontsize", 24);

work = trapz(position_clipped, spine_predict_force - zero_force);
work

# recognize the different parts of the curves
# use the position curve since it is less noisy and is set by the machine
section = cell(1, rows(X));
current = "depress";
idx_depress_to_hold = 0;
idx_hold_to_pull = 0;
idx_pull_to_reset = 0;
for i=1:length(section)
  if i == 1
    section{i} = "depress";
    disp("start");
  elseif position(i) > position(i-1) && strcmp(current, "depress")
    section{i} = "depress";
  elseif position(i) == position(i-1) && strcmp(current, "depress")
    current = "hold";
    section{i} = "hold";
    idx_depress_to_hold = i;
    disp("Switch from depress to hold");
  elseif position(i) == position(i-1) && strcmp(current, "hold")
    section(i) = "hold";
  elseif position(i) < position(i-1) && strcmp(current, "hold")
    current = "pull";
    section{i} = "pull";
    idx_hold_to_pull = i;
    disp("switch from hold to pull");
  elseif position(i) < position(i-1) && strcmp(current, "pull")
    section{i} = "pull";
  elseif position(i) > position(i-1) && strcmp(current, "pull")
    current = "reset";
    section{i} = "reset";
    idx_pull_to_reset = i;
    disp("switch from pull to reset");
  elseif position(i) > position(i-1) && strcmp(current, "reset")
    section{i} = "reset";
  end
end

# set the zero force to the mean of the reset region
zero_force = mean(force(idx_pull_to_reset:length(force)));
zero_force_std = std(force(idx_pull_to_reset:length(force)));
position_a = position(idx_pull_to_reset);
position_b = min(90.0, position(idx_hold_to_pull));
zero_force_trim = zero_force - 3*zero_force_std;
# find all points where position is between position_a and position_b and force is less that the zero line
idx = position > position_a  & position < position_b & force < zero_force_trim;
position_clipped = position(idx);
force_clipped = force(idx);

breaks = linspace(position_a, position_b, 100);
spline_force = splinefit(position_clipped, force_clipped, breaks, 
    "order", 2, "periodic", true);
# predict the splines
spline_predict_force = ppval(spline_force, position_clipped);

figure(5, "position", [1,1,1800,1200]);
# plot the data with blue circles ("ob") and the spline with red lines ("-r")
plot(position_clipped, force_clipped, "ob", 
     position_clipped, spline_predict_force, "-r");
xlabel("Position (mm)");
ylabel("Force (N)");
set(gca, "fontsize", 24);

work = trapz(position_clipped, spine_predict_force - zero_force);
work
