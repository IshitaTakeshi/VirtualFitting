% Copyright (C) 2015 Ishita Takeshi
%
% This program is free software: you can redistribute it and/or modify
% it under the terms of the GNU General Public License as published by
% the Free Software Foundation, either version 3 of the License, or
% (at your option) any later version.
%
% This program is distributed in the hope that it will be useful,
% but WITHOUT ANY WARRANTY; without even the implied warranty of
% MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
% GNU General Public License for more details.
%
% You should have received a copy of the GNU General Public License
% along with this program.  If not, see <http://www.gnu.org/licenses/>.


% Preparing animate-reshape dataset
%
% Images will be cropped and stored into
% <the path to this file>/animate-reshape/cropped with their annotations.
%
% The left upper corner of the cropped image is regarded as the origin of
% coordinates.
%
%Generated images and their annotations can be seen by the command below:
%$python3 plot_overlaid.py <path_to_image> <path_to_annotations>


pkg load image;


function cropped = crop_image(image, annotations)
  upper_left = annotations(:, 1);
  lower_right = annotations(:, 2);
  cell = num2cell(lower_right-upper_left);
  cropped = imcrop(image, [upper_left, lower_right-upper_left]);
end


function a = shift_annotations(annotations)
  upper_left = annotations(:, 1);
  a = bsxfun(@minus, annotations(:, 3:18), upper_left);
end


%change the order of annotations since the trainer doesn't allow the default
function annotations = change_order(annotations)
  annotations = annotations(
    :, [14, 13, 16, 9, 8, 7, 10, 11, 12, 15, 3, 2, 1, 4, 5, 6]
  );
end


function download(url, directory)
  if(nargin < 2)
    directory = '.'
  end
  system(sprintf('wget %s -P %s', url, directory));
end


function prepare_positive(positive_dir, crop)
  if(nargin < 2)
    crop = true;
  end

  tmp_dir = 'tmp';

  if not(exist(positive_dir))
    mkdir(positive_dir);
  end

  if not(exist(fullfile(pwd, 'animate-reshape-dataset.zip')))
    download(['http://datasets.d2.mpi-inf.mpg.de/'...
              'leonid12cvpr/animate-reshape-dataset.zip']);
  end

  unzip('animate-reshape-dataset.zip');

  if not(exist(tmp_dir))
    movefile('animate-reshape-dataset', tmp_dir);
  end

  load(fullfile(tmp_dir, 'annotations.mat'));

  for i = 1:length(images)
    image_path = fullfile(tmp_dir, images{i}.name);
    annotations = cell2mat(images{i}.annotations);

    image = imread(image_path);

    if(crop)
      image = crop_image(image, annotations);
      annotations = shift_annotations(annotations);
    else
      annotations = annotations(:, 3:18);
    end

    annotations = change_order(annotations);

    path = strrep(fullfile(positive_dir, images{i}.name), '.png', '.txt');
    csvwrite(path, annotations');

    path = fullfile(positive_dir, images{i}.name);
    imwrite(image, path);
  end

  rmdir(tmp_dir, 's');
end


function prepare_negative(negative_dir)
  if not(exist(fullfile(pwd, 'people.zip')))
    download('http://www.ics.uci.edu/~dramanan/papers/parse/people.zip');
  end

  unzip('people.zip');

  if not(exist(negative_dir))
    movefile('people_all', negative_dir);
  end
end


dataset_root = 'animate-reshape';
crop = false;

if not(exist(dataset_root))
  mkdir(dataset_root);
end

positive_dir = fullfile(dataset_root, 'positive');
negative_dir = fullfile(dataset_root, 'negative');

prepare_positive(positive_dir, crop);
prepare_negative(negative_dir);
