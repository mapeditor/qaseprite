// Copyright (C) 2024  Thorbjørn Lindeijer
//
// This file is released under the terms of the MIT license.
// Read LICENSE.txt for more information.

#include <dio/decode_delegate.h>
#include <dio/decode_file.h>
#include <dio/detect_format.h>
#include <dio/file_interface.h>
#include <doc/image.h>
#include <render/render.h>

#include <QImage>
#include <QImageIOPlugin>

class QtFileInterface final : public dio::FileInterface {
public:
    QtFileInterface(QIODevice *device)
        : m_device(device)
    {}

    bool ok() const override { return m_ok; }
    size_t tell() override { return m_device->pos(); }

    void seek(size_t absPos) override
    {
        if (!m_device->seek(absPos))
            m_ok = false;
    }

    uint8_t read8() override
    {
        char c;
        if (!m_device->getChar(&c))
            m_ok = false;
        return c;
    }

    size_t readBytes(uint8_t *buf, size_t n) override
    {
        auto bytesRead = m_device->read(reinterpret_cast<char *>(buf), n);
        if (bytesRead == -1)
            m_ok = false;
        return bytesRead;
    }

    void write8(uint8_t value) override
    {
        if (!m_device->putChar(value))
            m_ok = false;
    }

private:
    QIODevice *m_device;
    bool m_ok = true;
};

class DecodeDelegate final : public dio::DecodeDelegate {
public:
    DecodeDelegate() = default;
    ~DecodeDelegate() { delete m_sprite; }

    void error(const std::string &msg) override
    {
        qWarning("QAsepriteHandler: Error: %s", msg.c_str());
    }

    void incompatibilityError(const std::string &msg) override
    {
        qWarning("QAsepriteHandler: Incompatibility error: %s", msg.c_str());
    }

    bool decodeOneFrame() override { return true; }
    void onSprite(doc::Sprite *sprite) override { m_sprite = sprite; }
    doc::Sprite *sprite() { return m_sprite; }

private:
    doc::Sprite *m_sprite = nullptr;
};

class QAsepriteHandler : public QImageIOHandler {
public:
    bool canRead() const override
    {
        if (canRead(device())) {
            setFormat("ase");
            return true;
        }

        return false;
    }

    bool read(QImage *dest) override
    {
        // This code is based on the desktop::ThumbnailHandler::GetThumbnail()
        // function from the Aseprite's Windows thumbnailer.

        std::unique_ptr<doc::Image> image;

        try {
            DecodeDelegate delegate;
            QtFileInterface fileInterface(device());
            if (!dio::decode_file(&delegate, &fileInterface))
                return false;

            const doc::Sprite *sprite = delegate.sprite();

            image.reset(doc::Image::create(doc::IMAGE_RGB, sprite->width(), sprite->height()));

            render::Render render;
            render.renderSprite(image.get(), sprite, doc::frame_t(0));

        } catch (const std::exception &) {
            return false;
        }

        // Construct a QImage around the existing memory buffer
        const QImage img(image->getPixelAddress(0, 0),
                         image->width(),
                         image->height(),
                         image->rowBytes(),
                         QImage::Format_RGBA8888);

        // Convert to a more common format while copying the data
        *dest = img.convertToFormat(QImage::Format_ARGB32);

        return true;
    }

    static bool canRead(QIODevice *device)
    {
        if (!device)
            return false;

        const QByteArray header = device->peek(8);
        const uint8_t *headerBuffer = reinterpret_cast<const uint8_t *>(header.constData());
        const dio::FileFormat format = dio::detect_format_by_file_content_bytes(headerBuffer,
                                                                                header.size());

        return format == dio::FileFormat::ASE_ANIMATION;
    }
};

class AsepriteImagePlugin : public QImageIOPlugin {
    Q_OBJECT
    Q_PLUGIN_METADATA(IID QImageIOHandlerFactoryInterface_iid FILE "qaseprite.json")

public:
    explicit AsepriteImagePlugin(QObject *parent = nullptr)
        : QImageIOPlugin(parent)
    {}

    QImageIOPlugin::Capabilities capabilities(QIODevice *device,
                                              const QByteArray &format) const override
    {
        if (format == "ase" || format == "aseprite")
            return CanRead;

        if (device && device->isReadable() && QAsepriteHandler::canRead(device))
            return CanRead;

        return {};
    }

    QImageIOHandler *create(QIODevice *device, const QByteArray &format) const override
    {
        QImageIOHandler *handler = new QAsepriteHandler;
        handler->setDevice(device);
        handler->setFormat(format);
        return handler;
    }
};

#include "qaseprite.moc"
