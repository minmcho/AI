import { useCallback } from 'react'

interface ImageUploaderProps {
  onImageUpload: (imageData: string) => void
}

export default function ImageUploader({ onImageUpload }: ImageUploaderProps) {
  const handleFileChange = useCallback(
    (event: React.ChangeEvent<HTMLInputElement>) => {
      const file = event.target.files?.[0]
      if (file && file.type.startsWith('image/')) {
        const reader = new FileReader()
        reader.onload = (e) => {
          const imageData = e.target?.result as string
          onImageUpload(imageData)
        }
        reader.readAsDataURL(file)
      }
    },
    [onImageUpload]
  )

  const handleDrop = useCallback(
    (event: React.DragEvent<HTMLDivElement>) => {
      event.preventDefault()
      const file = event.dataTransfer.files?.[0]
      if (file && file.type.startsWith('image/')) {
        const reader = new FileReader()
        reader.onload = (e) => {
          const imageData = e.target?.result as string
          onImageUpload(imageData)
        }
        reader.readAsDataURL(file)
      }
    },
    [onImageUpload]
  )

  const handleDragOver = (event: React.DragEvent<HTMLDivElement>) => {
    event.preventDefault()
  }

  return (
    <div className="max-w-2xl mx-auto">
      <div
        onDrop={handleDrop}
        onDragOver={handleDragOver}
        className="border-4 border-dashed border-blue-400 rounded-lg p-12 bg-white bg-opacity-10 backdrop-blur-sm hover:bg-opacity-20 transition-all cursor-pointer"
      >
        <div className="text-center">
          <svg
            className="mx-auto h-24 w-24 text-blue-300 mb-4"
            stroke="currentColor"
            fill="none"
            viewBox="0 0 48 48"
            aria-hidden="true"
          >
            <path
              d="M28 8H12a4 4 0 00-4 4v20m32-12v8m0 0v8a4 4 0 01-4 4H12a4 4 0 01-4-4v-4m32-4l-3.172-3.172a4 4 0 00-5.656 0L28 28M8 32l9.172-9.172a4 4 0 015.656 0L28 28m0 0l4 4m4-24h8m-4-4v8m-12 4h.02"
              strokeWidth={2}
              strokeLinecap="round"
              strokeLinejoin="round"
            />
          </svg>
          <h3 className="text-2xl font-semibold text-white mb-2">
            Upload an image
          </h3>
          <p className="text-blue-200 mb-6">
            Drag and drop or click to select
          </p>
          <label className="inline-block cursor-pointer bg-blue-600 hover:bg-blue-700 text-white font-bold py-3 px-8 rounded-lg transition-colors">
            Choose File
            <input
              type="file"
              accept="image/*"
              onChange={handleFileChange}
              className="hidden"
            />
          </label>
        </div>
      </div>
    </div>
  )
}
