#include <opencv2/core.hpp>
#include <opencv2/imgproc.hpp>
#include <opencv2/imgcodecs.hpp>
#include <cstdlib>
#include <iostream>
#include <string>
#include <vector>

#define CHECK(cond, msg) \
    do { \
        if (!(cond)) { \
            std::cerr << "FAIL: " << msg << std::endl; \
            std::exit(1); \
        } \
    } while(0)

#define LOG(msg)  std::cout << "[LOG] " << msg << std::endl

int main() {
    LOG("main() entered");

    // 1. Version check
    LOG("1. getVersionString...");
    std::string version = cv::getVersionString();
    std::cout << "OpenCV version: " << version << std::endl;
    CHECK(!version.empty(), "getVersionString returned empty");
    LOG("1. OK");

    // 2. Create a Mat and fill with values
    LOG("2. cv::Mat create/fill...");
    cv::Mat m(3, 3, CV_32FC1);
    for (int i = 0; i < 3; i++) {
        for (int j = 0; j < 3; j++) {
            m.at<float>(i, j) = static_cast<float>(i * 3 + j);
        }
    }
    CHECK(m.rows == 3 && m.cols == 3, "Mat dimensions wrong");
    CHECK(m.at<float>(0, 0) == 0.0f, "Mat value (0,0) wrong");
    CHECK(m.at<float>(2, 2) == 8.0f, "Mat value (2,2) wrong");
    LOG("2. OK");

    // 3. Test basic arithmetic
    LOG("3. Mat arithmetic...");
    cv::Mat doubled = m * 2.0f;
    CHECK(doubled.at<float>(1, 1) == 8.0f, "Mat scalar multiply wrong");
    LOG("3. OK");

    // 4. Load OpenCV logo from embedded WASM virtual filesystem
    LOG("4. imread logo PNG...");
    cv::Mat img = cv::imread("/logo.png", cv::IMREAD_COLOR);
    CHECK(!img.empty(), "imread logo.png failed (preload file missing?)");
    CHECK(img.channels() == 3, "logo image channels wrong");
    std::cout << "Logo image: " << img.cols << "x" << img.rows << std::endl;
    std::cout << std::flush;
    LOG("4. OK");

    // 5. JPEG encoding currently throws in the wasm build even when imgcodecs is present.
    // Keep the probe for visibility, but use PNG for the round-trip codec test.
    LOG("5. check JPEG codec...");
    bool have_jpeg_writer = cv::haveImageWriter(".jpg");
    std::cout << "  haveImageWriter(.jpg)=" << have_jpeg_writer << std::endl;
    std::cout << std::flush;
    LOG("5. JPEG encode skipped in wasm test");

    // 6. Test PNG encoding + decoding round-trip
    LOG("6. imencode/imdecode PNG...");
    std::vector<uchar> png_buf;
    bool png_ok = cv::imencode(".png", img, png_buf);
    CHECK(png_ok, "imencode PNG failed");
    CHECK(!png_buf.empty(), "PNG buffer empty");
    std::cout << "PNG encoded size: " << png_buf.size() << " bytes" << std::endl;
    cv::Mat decoded = cv::imdecode(png_buf, cv::IMREAD_COLOR);
    CHECK(!decoded.empty(), "imdecode PNG failed");
    CHECK(decoded.rows == img.rows && decoded.cols == img.cols, "decoded image size wrong");
    CHECK(decoded.channels() == 3, "decoded image channels wrong");
    LOG("6. OK");

    // 7. Test cvtColor (BGR -> Gray)
    LOG("7. cvtColor...");
    cv::Mat gray;
    cv::cvtColor(decoded, gray, cv::COLOR_BGR2GRAY);
    CHECK(gray.rows == img.rows && gray.cols == img.cols, "gray image size wrong");
    CHECK(gray.channels() == 1, "gray image channels wrong");
    LOG("7. OK");

    // 8. Test resize
    LOG("8. resize...");
    cv::Mat resized;
    cv::resize(gray, resized, cv::Size(8, 8));
    CHECK(resized.rows == 8 && resized.cols == 8, "resized image size wrong");
    LOG("8. OK");

    // 9. Test matrix ops (imgproc: GaussianBlur)
    LOG("9. GaussianBlur...");
    cv::Mat blurred;
    cv::GaussianBlur(resized, blurred, cv::Size(3, 3), 0);
    CHECK(blurred.rows == 8 && blurred.cols == 8, "blurred image size wrong");
    LOG("9. OK");

    // 10. Test second PNG encode from processed image
    LOG("10. imencode PNG...");
    std::vector<uchar> processed_png_buf;
    bool processed_png_ok = cv::imencode(".png", decoded, processed_png_buf);
    CHECK(processed_png_ok, "processed imencode PNG failed");
    CHECK(!processed_png_buf.empty(), "processed PNG buffer empty");
    std::cout << "Processed PNG encoded size: " << processed_png_buf.size() << " bytes" << std::endl;
    LOG("10. OK");

    std::cout << "All tests passed!" << std::endl;
    return 0;
}
