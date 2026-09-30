// Functional test for boost-wave, adapted from
// libs/wave/test/testwave/testwave.cpp

#include <boost/wave.hpp>
#include <boost/wave/cpplexer/cpp_lex_token.hpp>
#include <boost/wave/cpplexer/cpp_lex_iterator.hpp>
#include <string>

int main()
{
    std::string input("int main() { return 42; }\n");

    typedef boost::wave::cpplexer::lex_token<> token_type;
    typedef boost::wave::cpplexer::lex_iterator<token_type> lexer_type;
    typedef boost::wave::context<std::string::iterator, lexer_type> context_type;

    try
    {
        context_type ctx(input.begin(), input.end(), "wave_test.cpp");

        // collect token text, concatenate; token text is flex_string
        token_type::string_type joined;
        std::size_t n = 0;
        context_type::iterator_type it = ctx.begin();
        context_type::iterator_type end = ctx.end();
        for (; it != end; ++it)
        {
            if (boost::wave::token_id(*it) != boost::wave::T_EOF)
            {
                joined += it->get_value();
                ++n;
            }
        }

        if (n < 3) return 1;
        if (joined.size() == 0) return 1;
    }
    catch (...)
    {
        return 1; // lexing error
    }

    return 0;
}