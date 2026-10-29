# frozen_string_literal: true

require "rails_helper"

unless ENV["DISABLE_ACTIVE_STORAGE"] == "true"
  RSpec.describe Spree::ActiveStorageAdapter::Attachment do
    include ImageSpecHelper

    describe "#variant" do
      context "with a real landscape image" do
        let(:image) { create(:image, attachment: open_image("landscape.png")) }

        def processed_image(style)
          attachment = described_class.new(image.attachment.attachment, styles: {preview: style})
          MiniMagick::Image.read(attachment.variant(:preview).download)
        end

        it "resizes without distorting the aspect ratio and strips metadata" do
          result = processed_image("60x60>")
          expect([result.width, result.height]).to eq([60, 40])
          expect(result["%c"]).to eq("")
          expect(result.type).to eq("PNG")
        ensure
          result&.destroy!
        end

        it "crops to the requested dimensions" do
          result = processed_image("30x30^")
          expect([result.width, result.height]).to eq([30, 30])
        ensure
          result&.destroy!
        end

        it "preserves transparency" do
          result = processed_image("60x60>")
          expect(result["%[opaque]"].downcase).to eq("false")
        ensure
          result&.destroy!
        end
      end

      it "converts to resize_to_limit when definition doesn't contain any special symbol" do
        image = create(:image)

        attachment = described_class.new(image.attachment.attachment, styles: {mini: "10x10"})

        expect(
          attachment.variant(:mini).variation.transformations
        ).to include(resize_to_limit: [10, 10])
      end

      it "converts to resize_to_limit when definition ends with >" do
        image = create(:image)

        attachment = described_class.new(image.attachment.attachment, styles: {mini: "10x10>"})

        expect(
          attachment.variant(:mini).variation.transformations
        ).to include(resize_to_limit: [10, 10])
      end

      it "converts to resize_to_fill when definition ends with ^" do
        image = create(:image)

        attachment = described_class.new(image.attachment.attachment, styles: {mini: "10x10^"})

        expect(
          attachment.variant(:mini).variation.transformations
        ).to include(resize_to_fill: [10, 10])
      end

      it "strips definitions" do
        image = create(:image)

        attachment = described_class.new(image.attachment.attachment, styles: {mini: " 10x10 "})

        expect(
          attachment.variant(:mini).variation.transformations
        ).to include(resize_to_limit: [10, 10])
      end

      it "defaults to the image's width and height" do
        image = create(:image)

        attachment = described_class.new(image.attachment.attachment, styles: {})

        expect(
          attachment.variant(:mini).variation.transformations
        ).to include(resize_to_limit: [attachment.width, attachment.height])
      end
    end
  end
end
