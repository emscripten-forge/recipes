pkg rebuild -global;
pkg load image;
disp(which('imresize'));
I = magic(8);
J = imresize(I, 0.5);
disp(size(J));
