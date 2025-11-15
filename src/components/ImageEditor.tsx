import { useState, useEffect, useRef } from 'react'
import ImageFilters from './ImageFilters'

interface ImageEditorProps {
  image: string
  onReset: () => void
}

export interface FilterSettings {
  brightness: number
  contrast: number
  saturation: number
  blur: number
  grayscale: number
  sepia: number
  hueRotate: number
  invert: number
}

export default function ImageEditor({ image, onReset }: ImageEditorProps) {
  const canvasRef = useRef<HTMLCanvasElement>(null)
  const [filters, setFilters] = useState<FilterSettings>({
    brightness: 100,
    contrast: 100,
    saturation: 100,
    blur: 0,
    grayscale: 0,
    sepia: 0,
    hueRotate: 0,
    invert: 0,
  })

  useEffect(() => {
    const canvas = canvasRef.current
    if (!canvas) return

    const ctx = canvas.getContext('2d')
    if (!ctx) return

    const img = new Image()
    img.onload = () => {
      canvas.width = img.width
      canvas.height = img.height
      applyFilters(ctx, img)
    }
    img.src = image
  }, [image, filters])

  const applyFilters = (ctx: CanvasRenderingContext2D, img: HTMLImageElement) => {
    const filterString = `
      brightness(${filters.brightness}%)
      contrast(${filters.contrast}%)
      saturate(${filters.saturation}%)
      blur(${filters.blur}px)
      grayscale(${filters.grayscale}%)
      sepia(${filters.sepia}%)
      hue-rotate(${filters.hueRotate}deg)
      invert(${filters.invert}%)
    `.trim()

    ctx.filter = filterString
    ctx.drawImage(img, 0, 0)
  }

  const handleFilterChange = (filterName: keyof FilterSettings, value: number) => {
    setFilters((prev) => ({
      ...prev,
      [filterName]: value,
    }))
  }

  const handleReset = () => {
    setFilters({
      brightness: 100,
      contrast: 100,
      saturation: 100,
      blur: 0,
      grayscale: 0,
      sepia: 0,
      hueRotate: 0,
      invert: 0,
    })
  }

  const handleDownload = () => {
    const canvas = canvasRef.current
    if (!canvas) return

    const link = document.createElement('a')
    link.download = 'radiant-vision-edited.png'
    link.href = canvas.toDataURL()
    link.click()
  }

  return (
    <div className="max-w-7xl mx-auto">
      <div className="grid grid-cols-1 lg:grid-cols-3 gap-8">
        <div className="lg:col-span-2">
          <div className="bg-white bg-opacity-10 backdrop-blur-sm rounded-lg p-6">
            <div className="flex justify-between items-center mb-4">
              <h2 className="text-2xl font-bold text-white">Preview</h2>
              <div className="space-x-2">
                <button
                  onClick={handleDownload}
                  className="bg-green-600 hover:bg-green-700 text-white font-bold py-2 px-4 rounded transition-colors"
                >
                  Download
                </button>
                <button
                  onClick={onReset}
                  className="bg-red-600 hover:bg-red-700 text-white font-bold py-2 px-4 rounded transition-colors"
                >
                  New Image
                </button>
              </div>
            </div>
            <div className="overflow-auto max-h-[600px] bg-gray-900 rounded-lg p-4">
              <canvas
                ref={canvasRef}
                className="max-w-full h-auto mx-auto"
              />
            </div>
          </div>
        </div>

        <div className="lg:col-span-1">
          <ImageFilters
            filters={filters}
            onFilterChange={handleFilterChange}
            onReset={handleReset}
          />
        </div>
      </div>
    </div>
  )
}
