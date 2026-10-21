#include <itkImage.h>
#include <itkImageFileWriter.h>
#include <itkImageFileReader.h>
#include <itkGDCMImageIO.h>
#include <itkHDF5ImageIO.h>
#include <itkImageRegionIterator.h>
#include <itkGradientMagnitudeImageFilter.h>
#include <itkThreadLogger.h>
#include <itkLogOutput.h>
#include <itkMacro.h>
#include <iostream>

using Image = itk::Image<unsigned short, 2>;

static void step(const char* s) { std::cout << "STEP " << s << std::endl; }

namespace
{
// Records whether ThreadLogger actually delivered a message.  On emscripten,
// ThreadLogger cannot spawn its worker thread (patches/0001), so it logs
// synchronously; if that delegation regressed, messages would stay queued and
// this flag would never be set.
class ProbeLogOutput : public itk::LogOutput
{
public:
  using Self = ProbeLogOutput;
  using Superclass = itk::LogOutput;
  using Pointer = itk::SmartPointer<Self>;
  itkNewMacro(Self);

  bool seen = false;

  void Flush() override {}
  void Write(double) override {}
  void Write(const std::string & content) override
  {
    if (content.find("libitk logger") != std::string::npos)
    {
      seen = true;
    }
  }
  void Write(const std::string & content, double) override { this->Write(content); }
};
} // namespace

int main()
{
  try {
    step("alloc");
    auto image = Image::New();
    Image::SizeType size = {{ 8, 8 }};
    Image::IndexType start = {{ 0, 0 }};
    Image::RegionType region(start, size);
    image->SetRegions(region);
    image->Allocate();
    itk::ImageRegionIterator<Image> it(image, region);
    unsigned short value = 1;
    for (it.GoToBegin(); !it.IsAtEnd(); ++it) { it.Set(value++); }

    step("gradient");
    auto filter = itk::GradientMagnitudeImageFilter<Image, Image>::New();
    filter->SetInput(image);
    filter->Update();

    step("png-write");
    itk::ImageFileWriter<Image>::Pointer writer = itk::ImageFileWriter<Image>::New();
    writer->SetFileName("test_itk.png");
    writer->SetInput(image);
    writer->Update();

    step("png-read");
    itk::ImageFileReader<Image>::Pointer reader = itk::ImageFileReader<Image>::New();
    reader->SetFileName("test_itk.png");
    reader->Update();

    step("gdcm");
    itk::GDCMImageIO::Pointer gdcm = itk::GDCMImageIO::New();
    std::cout << "gdcm class: " << gdcm->GetNameOfClass() << std::endl;

    step("logger");
    itk::ThreadLogger::Pointer logger = itk::ThreadLogger::New();
    ProbeLogOutput::Pointer    probe = ProbeLogOutput::New();
    logger->AddLogOutput(probe);
    logger->SetPriorityLevel(itk::LoggerBase::PriorityLevelEnum::INFO);
    logger->SetLevelForFlushing(itk::LoggerBase::PriorityLevelEnum::MUSTFLUSH);
    logger->Write(itk::LoggerBase::PriorityLevelEnum::INFO, "libitk logger");
    logger->Flush();
    if (!probe->seen)
    {
      std::cerr << "ThreadLogger dropped the message" << std::endl;
      return 5;
    }

    step("hdf5-write");
    itk::HDF5ImageIO::Pointer hdf5 = itk::HDF5ImageIO::New();
    hdf5->SetFileName("test_itk.h5");
    hdf5->SetNumberOfDimensions(2);
    hdf5->SetDimensions(0, size[0]);
    hdf5->SetDimensions(1, size[1]);
    hdf5->SetComponentType(itk::IOComponentEnum::USHORT);
    hdf5->Write(image);

    std::cout << "libitk ok" << std::endl;
    return 0;
  } catch (const itk::ExceptionObject & e) {
    std::cerr << "ITK EXCEPTION: " << e << std::endl; return 2;
  } catch (const std::exception & e) {
    std::cerr << "STD EXCEPTION: " << e.what() << std::endl; return 3;
  } catch (...) {
    std::cerr << "UNKNOWN EXCEPTION" << std::endl; return 4;
  }
}
