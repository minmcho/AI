import { useState } from 'react'
import ImageUploader from './components/ImageUploader'
import ImageEditor from './components/ImageEditor'
import './App.css'

function App() {
  const [image, setImage] = useState<string | null>(null)

  const handleImageUpload = (imageData: string) => {
    setImage(imageData)
  }

  const handleReset = () => {
    setImage(null)
  }

  return (
    <div className="min-h-screen bg-gradient-to-br from-purple-900 via-blue-900 to-indigo-900">
      <div className="container mx-auto px-4 py-8">
        <header className="text-center mb-12">
          <h1 className="text-5xl font-bold text-white mb-4">
            ✨ Radiant Vision
          </h1>
          <p className="text-xl text-blue-200">
            Transform your images with powerful processing tools
          </p>
        </header>

        <main>
          {!image ? (
            <ImageUploader onImageUpload={handleImageUpload} />
          ) : (
            <ImageEditor image={image} onReset={handleReset} />
          )}
        </main>

        <footer className="mt-16 text-center text-blue-300">
          <p>Built with React, TypeScript, and Tailwind CSS</p>
        </footer>
      </div>
    </div>
  )
}

export default App
