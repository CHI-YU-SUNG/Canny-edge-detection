clear all;  close all;  clc;
% 600*881
origin_img = imread('image-pj6(Canny).tif');
% initial 
sigma = 3;  % 600 * 0.5% = 3
filter_size = 19;   % should larger than 6 * sigma = 6 * 3 = 18

% generate gaussian filter
gaussian_filter = fspecial('gaussian', filter_size, sigma);
conv_im = conv2(origin_img, gaussian_filter, 'same');
% caculate gradient with sobel operator
[gaussian_filter_x gaussian_filter_y] = gradient(gaussian_filter);
gradient_x = conv2(conv_im, gaussian_filter_x, 'same');
gradient_y = conv2(conv_im, gaussian_filter_y, 'same');
% gradient magnitude
gradient_magnitude = sqrt(gradient_x.^2 + gradient_y.^2);
% gradient angle
gradient_angle = atan2(gradient_y, gradient_x)*180/pi;
% output
figure;
subplot(1,2,1), imshow(gradient_magnitude, []), title('gradient magnitude');
subplot(1,2,2), imshow(gradient_angle, []), title('gradient angle');
% angle normalize   
% -22.5 ~ 22.5  or 157.5 ~ -157.5   -> 0
% 22.5 ~ 67.5   or -112.5 ~ -157.5  -> 45
% 67.5 ~ 112.5  or -67.5 ~ -112.5   -> 90
% -22.5 ~ -67.5 or 112.5 ~ 157.5    -> 135

angle_normalize = zeros(600, 881);
for i = 1  : 600
    for j = 1 : 881
        angle = gradient_angle(i, j);
        if ( (angle <= 22.5 && angle > -22.5) || angle < -157.5 || angle >= 157.5)
            angle_normalize(i, j) = 0;
        elseif ( (angle <= 67.5 && angle > 22.5) || (angle <= -112.5 && angle > -157.5))
            angle_normalize(i, j) = 45;
        elseif ( (angle <= 112.5 && angle > 67.5) || (angle <= -67.5 && angle > -112.5))
            angle_normalize(i, j) = 90;
        elseif ( (angle <= -22.5 && angle > -67.5) || (angle <= 157.5 && angle > 112.5))
            angle_normalize(i, j) = 135;
        end
    end
end

% compare gradient with neighboring pixels
supressed_im = zeros(600, 881);
for i = 2  : 599
    for j = 2 : 880       
        if (angle_normalize(i, j) == 0)
        	if (gradient_magnitude(i, j) > gradient_magnitude(i, j - 1) && gradient_magnitude(i, j) > gradient_magnitude(i, j + 1))
                supressed_im(i, j) = gradient_magnitude(i, j);
            else
                supressed_im(i, j) = 0;
            end
        elseif (angle_normalize(i, j) == 45)
            if (gradient_magnitude(i, j) > gradient_magnitude(i + 1, j - 1) && gradient_magnitude(i, j) > gradient_magnitude(i - 1, j + 1))
                supressed_im(i, j) = gradient_magnitude(i, j);
            else
                supressed_im(i, j) = 0;
            end
        elseif (angle_normalize(i, j) == 90)
            if (gradient_magnitude(i, j) > gradient_magnitude(i - 1, j) && gradient_magnitude(i, j) > gradient_magnitude(i + 1, j))
                supressed_im(i, j) = gradient_magnitude(i, j);
            else
                supressed_im(i, j) = 0;
            end
        elseif (gradient_angle(i, j) == 135)
            if (gradient_magnitude(i, j) > gradient_magnitude(i - 1, j - 1) && gradient_magnitude(i, j) > gradient_magnitude(i + 1, j + 1))
                supressed_im(i, j) = gradient_magnitude(i, j);
            else
                supressed_im(i, j) = 0;
            end
        end
    end
end
low_threshold = max(max(supressed_im))*0.04;
high_threshold = max(max(supressed_im))*0.1;
thresh_im = zeros(600, 881);
for i = 1  : 600
    for j = 1 : 881
        if (supressed_im(i, j) < low_threshold)
            thresh_im(i, j) = 0;
        elseif (supressed_im(i, j) > high_threshold)
            thresh_im(i, j) = 1;
        else
            if ((supressed_im(i + 1, j) > high_threshold) || (supressed_im(i - 1, j) > high_threshold) || (supressed_im(i, j + 1) > high_threshold) || (supressed_im(i, j - 1) > high_threshold))
                thresh_im(i, j) = 1;
            end
        end
    end
end
figure;
subplot(1,2,1), imshow(thresh_im, []), title('output image');
subplot(1,2,2), imshow(origin_img), title('origin image');