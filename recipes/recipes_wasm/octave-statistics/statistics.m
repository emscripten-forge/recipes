pkg rebuild -global;
pkg load statistics;
disp(which('editDistance'));
assert(editDistance('kitten', 'sitting'), 3);
assert(normcdf(0), 0.5);
