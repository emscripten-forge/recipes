// Functional test for boost-program_options, adapted from
// libs/program_options/test/options_description_test.cpp

#include <boost/program_options.hpp>
#include <string>

int main()
{
    namespace po = boost::program_options;

    po::options_description desc("Test options");
    desc.add_options()
        ("value", po::value<int>()->required(), "an integer")
        ("flag", po::bool_switch()->default_value(false), "a flag");

    const char* argv[] = { "prog", "--value", "42", "--flag" };
    po::variables_map vm;
    po::store(po::parse_command_line(4, argv, desc), vm);
    po::notify(vm);

    if (!vm.count("value")) return 1;
    if (vm["value"].as<int>() != 42) return 1;
    if (vm["flag"].as<bool>() != true) return 1;

    return 0;
}