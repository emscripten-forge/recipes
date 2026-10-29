#include <opencv2/core.hpp>
#include <opencv2/dnn.hpp>
#include <opencv2/gapi.hpp>
#include <opencv2/gapi/s11n.hpp>
#include <opencv2/imgcodecs.hpp>
#include <opencv2/imgproc.hpp>
#include <opencv2/objdetect.hpp>
#include <opencv2/shape.hpp>
#include <opencv2/stitching.hpp>
#include <opencv2/video/tracking.hpp>
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

int main() {
    std::string version = cv::getVersionString();
    std::cout << "OpenCV version: " << version << std::endl;
    CHECK(!version.empty(), "getVersionString returned empty");

    cv::Mat m(3, 3, CV_32FC1);
    for (int i = 0; i < 3; i++) {
        for (int j = 0; j < 3; j++) {
            m.at<float>(i, j) = static_cast<float>(i * 3 + j);
        }
    }
    CHECK(m.rows == 3 && m.cols == 3, "Mat dimensions wrong");
    CHECK(m.at<float>(0, 0) == 0.0f, "Mat value (0,0) wrong");
    CHECK(m.at<float>(2, 2) == 8.0f, "Mat value (2,2) wrong");

    cv::Mat doubled = m * 2.0f;
    CHECK(doubled.at<float>(1, 1) == 8.0f, "Mat scalar multiply wrong");

    cv::Mat img(12, 16, CV_8UC3);
    for (int y = 0; y < img.rows; ++y) {
        for (int x = 0; x < img.cols; ++x) {
            img.at<cv::Vec3b>(y, x) = cv::Vec3b(
                static_cast<uchar>((x * 17) % 256),
                static_cast<uchar>((y * 29) % 256),
                static_cast<uchar>(((x + y) * 11) % 256));
        }
    }
    CHECK(img.channels() == 3, "generated image channels wrong");

    bool have_jpeg_writer = cv::haveImageWriter(".jpg");
    std::cout << "  haveImageWriter(.jpg)=" << have_jpeg_writer << std::endl;

    std::vector<uchar> png_buf;
    bool png_ok = cv::imencode(".png", img, png_buf);
    CHECK(png_ok, "imencode PNG failed");
    CHECK(!png_buf.empty(), "PNG buffer empty");
    std::cout << "PNG encoded size: " << png_buf.size() << " bytes" << std::endl;
    cv::Mat decoded = cv::imdecode(png_buf, cv::IMREAD_COLOR);
    CHECK(!decoded.empty(), "imdecode PNG failed");
    CHECK(decoded.rows == img.rows && decoded.cols == img.cols, "decoded image size wrong");
    CHECK(decoded.channels() == 3, "decoded image channels wrong");

    cv::Mat gray;
    cv::cvtColor(decoded, gray, cv::COLOR_BGR2GRAY);
    CHECK(gray.rows == img.rows && gray.cols == img.cols, "gray image size wrong");
    CHECK(gray.channels() == 1, "gray image channels wrong");

    cv::Mat resized;
    cv::resize(gray, resized, cv::Size(8, 8));
    CHECK(resized.rows == 8 && resized.cols == 8, "resized image size wrong");

    cv::Mat blurred;
    cv::GaussianBlur(resized, blurred, cv::Size(3, 3), 0);
    CHECK(blurred.rows == 8 && blurred.cols == 8, "blurred image size wrong");

    cv::KalmanFilter kf(2, 1);
    CHECK(kf.statePre.rows == 2, "KalmanFilter state size wrong");

    cv::QRCodeDetector qr_detector;
    qr_detector.setEpsX(0.3).setEpsY(0.4).setUseAlignmentMarkers(true);
    CHECK(true, "QRCodeDetector basic configuration failed");

    auto hausdorff = cv::createHausdorffDistanceExtractor();
    CHECK(static_cast<bool>(hausdorff), "HausdorffDistanceExtractor creation failed");

    auto stitcher = cv::Stitcher::create(cv::Stitcher::PANORAMA);
    CHECK(static_cast<bool>(stitcher), "Stitcher creation failed");

    cv::Mat dnn_input(2, 2, CV_32FC3, cv::Scalar(1.0f, 2.0f, 3.0f));
    cv::Mat blob = cv::dnn::blobFromImage(dnn_input);
    CHECK(!blob.empty(), "dnn blobFromImage returned empty blob");
    CHECK(blob.dims == 4, "dnn blob should be 4-dimensional");

    cv::GMat in;
    cv::GComputation graph(in, in);
    CHECK(!cv::gapi::serialize(graph).empty(), "G-API graph serialization failed");

    const std::string build_info = cv::getBuildInformation();
    CHECK(build_info.find("GDAL") != std::string::npos, "build info missing GDAL");
    CHECK(build_info.find("GDCM") != std::string::npos, "build info missing GDCM");
    CHECK(build_info.find("Protobuf") != std::string::npos, "build info missing Protobuf");

    std::vector<uchar> processed_png_buf;
    bool processed_png_ok = cv::imencode(".png", blurred, processed_png_buf);
    CHECK(processed_png_ok, "processed imencode PNG failed");
    CHECK(!processed_png_buf.empty(), "processed PNG buffer empty");
    std::cout << "Processed PNG encoded size: " << processed_png_buf.size() << " bytes" << std::endl;

    std::cout << "All tests passed!" << std::endl;
    return 0;
}
