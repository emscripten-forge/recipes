Module['preRun'] = () => {
    ENV['R_HOME'] = '/lib/R';
    ENV['R_ENABLE_JIT'] = '0';
    ENV['R_DEFAULT_PACKAGES'] = 'NULL';
    ENV["EDITOR"] = "vim";
};