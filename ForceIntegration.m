# need package io for reading excel
# only have to do with once
# pkg install -forge io

pkg load io;

[X, Xheader] = xlsread('SY1-30_12212018.xlsx');
position = X(:,1);
force = X(:,2);

plot(position, force)



[X, Xheader] = xlsread('SY1-50_12212018.xlsx');
position = X(:,1);
force = X(:,2);
time = 1:rows(X);

# plot the raw data
figure(1, "position", [1,1,1800,1200]);
plot(position, force);
xlabel("Position (mm)");
ylabel("Force (N)");
set(gca, "fontsize", 24);

# plot position vs time and force vs time
figure(1, "position", [1,1,1800,1200]);
plot(time, position, "linewidth", 3);
xlabel("Time");
ylabel("Position (mm)");
set(gca, "fontsize", 24);

figure(1, "position", [1,1,1800,1200]);
plot(time, force, "linewidth", 3);
xlabel("Time");
ylabel("Force (N)");
set(gca, "fontsize", 24);

# method1 - integrate force and zero curves
position_a = 89.45;
position_b = 90.0;
zero_force = -0.0610;
zero_force_trim = -0.0615;
max_force = min(force);
# find all points where position is between position_a and position_b and force is less that the zero line
idx = position > position_a  & position < position_b & force < zero_force_trim;
position_clipped = position(idx);
force_clipped = force(idx);

figure(1, "position", [1,1,1800,1200]);
plot(position_clipped, force_clipped);
xlabel("Position (mm)");
ylabel("Force (N)");
set(gca, "fontsize", 24);

work = trapz(position_clipped, force_clipped - zero_force);
work

# splinefitting 
# breaks is the places where the splines are fit together
# linpace fills the space with a certain number of points
breaks = linspace(position_a, position_b, 100);
spline_force = splinefit(position_clipped, force_clipped, breaks, "order", 2, "periodic", true);

figure(1, "position", [1,1,1800,1200]);
plot(position_clipped, force_clipped, "ob", 
     position_clipped, ppval(spline_force, position_clipped), "-r");
xlabel("Position (mm)");
ylabel("Force (N)");
set(gca, "fontsize", 24);



