%%%%%%%%%%
% CMSC660 Fall'11 Final Project: Affine Structure from Motion(SfM)
% doSfM.m
% Driver script to do affine SfM
%
% Angjoo Kanazawa 11/23/'11
%%%%%%%%%%
IMDIR = 'supp/images/'; % location of all images
OUTDIR = 'supp/'; % where to save mat files
TAU = 1000;
imFiles  = getImageSet(IMDIR); % gets cell array of frames
F = length(imFiles); % number of frames

%% Step 1: get initial keypoints
fprintf('getting intial keypoints from %s\n', imFiles{1});
[keyXs, keyYs]= getKeypoints(imread(imFiles{1}), TAU);    

% sfigure;
% imagesc(imread(imFiles{1})); colormap('gray'); hold on;
% plot(keyYs, keyXs, 'y.');
% title(['first frame overlayed with keypoints']);

%% Step 2: track features
% for each keypoint at frame f, I(x,y,f), we want to compute expected translation
% in the next frame I(x', y', f+1)
numPoints =  numel(keyXs);
if ~exist('tracked_points.mat');
    trackedXs = zeros(length(imFiles), numPoints);
    trackedYs = zeros(length(imFiles), numPoints);
    trackedXs(1, :) = keyXs; trackedYs(1, :) = keyYs;
    for i=2:length(imFiles)
        [trackedXs(i,:) trackedYs(i,:)] = predictTranslationAll(trackedXs(i-1, :), trackedYs(i-1, :),...
                                                          imread(imFiles{i-1}), imread(imFiles{i}));
    end
    save('tracked_points.mat', 'trackedXs', 'trackedYs');
else
    load('tracked_points.mat');
end

% remove nans i.e. points that went out of frame
outFrame = find(isnan(trackedXs(end, :)));
trackedXs(:, outFrame) = [];
trackedYs(:, outFrame) = [];
numPoints = numPoints - numel(outFrame);

%% Draw path of random 20 points

% X1toX2 = [keyXs trackedXs(2,:)'];
% Y1toY2 = [keyYs trackedYs(2,:)'];
%line(Y1toY2', X1toX2', 'color', 'b', 'LineStyle', '-.');

sfigure; imagesc(imread(imFiles{1})); colormap('gray'); hold on;
pt1 =  [trackedYs(1,:)' trackedXs(1,:)' ones(numPoints, 1)];
pt2 =  [trackedYs(2,:)' trackedXs(2,:)' ones(numPoints, 1)];
arrow(pt1, pt2, 'Length', 4, 'Width', 1, 'EdgeColor', 'y', ...
      'FaceColor', 'b');

%% Step 3: Affine Structure for Motion via Factorization

% load 'supp/tracked_points';

% sfigure; imagesc(imread(imFiles{1})); colormap('gray'); hold on;
% pt1 =  [Ys(1,:)' Xs(1,:)' ones(numPoints, 1)];
% pt2 =  [Ys(2,:)' Xs(2,:)' ones(numPoints, 1)];
% arrow(pt1, pt2, 'Length', 4, 'Width', 1, 'EdgeColor', 'y', ...
%       'FaceColor', 'b');

[M S] = do_factorization(trackedXs, trackedYs);

%% Step 4: plot the predicted 3D path of the cameras
%The camera position for each frame is given by the cross product
%kf = if × jf. For consistent results, normalize all kf to be unit
%vectors. Give three plots, one for each dimension of kf.
keyboard
camera_pos = zeros(F, 3);
for f = 1:F
    kf = cross(M(f,:), M(f+F, :));
    camera_pos(f,:) = kf/norm(kf); % in unit norm
end

% save this plot in 3 axis.......
%sfigure; plot3(camera_pos(:, 1), camera_pos(:, 2), camera_pos(:, 3),'.-');
sfigure; plot3(camera_pos(:, 1), camera_pos(:, 2), [1:F], '.-');
grid on; zlabel('frames');
title('camera position over frame on XY axis');
sfigure; plot(camera_pos(:, 1), camera_pos(:, 3), [1:F]);
grid on; zlabel('frames');
title('camera position over frame on XZ axis');
sfigure; plot(camera_pos(:, 2), camera_pos(:, 3));
grid on; zlabel('frames');
title('camera position over frame on YZ axis');
% triangulate..?
keyboard
X = S(1, :);
Y = S(2, :);
Z = S(3, :);
tri = delaunay(X,Y);
trisurf(tri, X,Y,Z);

mesh(X,Y,Z);

