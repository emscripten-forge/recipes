#include <iostream>
#include <string>

#include <minja/minja.hpp>
#include <minja/chat-template.hpp>

using json = nlohmann::ordered_json;

// Report helper
static int failures = 0;
#define CHECK(cond) \
    do { \
        if (!(cond)) { \
            std::cerr << "FAIL: " #cond " (line " << __LINE__ << ")" << std::endl; \
            ++failures; \
        } \
    } while (false)

// ---------------------------------------------------------------------------
// Test basic Jinja2 template parsing and rendering
// ---------------------------------------------------------------------------
void test_minja_basic() {
    std::cout << "Testing minja::Parser::parse + render..." << std::endl;

    auto tmpl = minja::Parser::parse("Hello, {{ name }}!", /* options= */ {});
    auto context = minja::Context::make(minja::Value(json{
        {"name", "World"}
    }));
    auto result = tmpl->render(context);
    CHECK(result == "Hello, World!");

    std::cout << "  minja basic rendering OK" << std::endl;
}

// ---------------------------------------------------------------------------
// Test Jinja2 conditionals
// ---------------------------------------------------------------------------
void test_minja_conditionals() {
    std::cout << "Testing minja conditionals..." << std::endl;

    auto tmpl = minja::Parser::parse(
        "{% if x > 10 %}big{% else %}small{% endif %}",
        /* options= */ {}
    );

    auto ctx_big = minja::Context::make(minja::Value(json{{"x", 20}}));
    CHECK(tmpl->render(ctx_big) == "big");

    auto ctx_small = minja::Context::make(minja::Value(json{{"x", 5}}));
    CHECK(tmpl->render(ctx_small) == "small");

    std::cout << "  minja conditionals OK" << std::endl;
}

// ---------------------------------------------------------------------------
// Test Jinja2 loops
// ---------------------------------------------------------------------------
void test_minja_loops() {
    std::cout << "Testing minja loops..." << std::endl;

    auto tmpl = minja::Parser::parse(
        "{% for item in items %}{{ item }}{% endfor %}",
        /* options= */ {}
    );

    auto context = minja::Context::make(minja::Value(json{
        {"items", json::array({"a", "b", "c"})}
    }));
    auto result = tmpl->render(context);
    CHECK(result == "abc");

    std::cout << "  minja loops OK" << std::endl;
}

// ---------------------------------------------------------------------------
// Test minja::chat_template with simple messages
// ---------------------------------------------------------------------------
void test_minja_chat_template_basic() {
    std::cout << "Testing minja::chat_template basic..." << std::endl;

    minja::chat_template tmpl(
        "{% for message in messages %}"
        "{{ '<|' + message['role'] + '|>\\n' + message['content'] + '<|end|>\\n' }}"
        "{% endfor %}",
        /* bos_token= */ "<|start|>",
        /* eos_token= */ "<|end|>"
    );

    minja::chat_template_inputs inputs;
    inputs.messages = json::parse(R"([
        {"role": "user", "content": "Hello"},
        {"role": "assistant", "content": "Hi there"}
    ])");
    inputs.add_generation_prompt = true;

    std::string result = tmpl.apply(inputs);
    CHECK(result.find("<|user|>") != std::string::npos);
    CHECK(result.find("Hello") != std::string::npos);
    CHECK(result.find("<|assistant|>") != std::string::npos);
    CHECK(result.find("Hi there") != std::string::npos);

    std::cout << "  minja chat_template basic OK" << std::endl;
}

// ---------------------------------------------------------------------------
// Test minja::chat_template with tools
// ---------------------------------------------------------------------------
void test_minja_chat_template_tools() {
    std::cout << "Testing minja::chat_template with tools..." << std::endl;

    minja::chat_template tmpl(
        "{% if messages[0]['role'] == 'system' %}{{ '<|system|>\\n' + messages[0]['content'] + '<|end|>\\n' }}{% endif %}"
        "{% for message in messages %}"
        "{% if message['role'] != 'system' %}"
        "{{ '<|' + message['role'] + '|>\\n' + message['content'] + '<|end|>\\n' }}"
        "{% endif %}"
        "{% endfor %}",
        /* bos_token= */ "",
        /* eos_token= */ ""
    );

    minja::chat_template_inputs inputs;
    inputs.messages = json::parse(R"([
        {"role": "system", "content": "You are helpful."},
        {"role": "user", "content": "What is 2+2?"}
    ])");
    inputs.add_generation_prompt = false;

    std::string result = tmpl.apply(inputs);
    CHECK(result.find("<|system|>") != std::string::npos);
    CHECK(result.find("You are helpful.") != std::string::npos);
    CHECK(result.find("<|user|>") != std::string::npos);
    CHECK(result.find("What is 2+2?") != std::string::npos);

    std::cout << "  minja chat_template tools OK" << std::endl;
}

// ---------------------------------------------------------------------------
// Main
// ---------------------------------------------------------------------------
int main() {
    test_minja_basic();
    test_minja_conditionals();
    test_minja_loops();
    test_minja_chat_template_basic();
    test_minja_chat_template_tools();

    std::cout << std::endl;
    if (failures) {
        std::cerr << failures << " test(s) FAILED!" << std::endl;
        return 1;
    }
    std::cout << "All minja tests passed!" << std::endl;
    return 0;
}
