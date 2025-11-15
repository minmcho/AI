# Radiant Vision App

A modern, powerful web-based image processing application built with React, TypeScript, and Tailwind CSS.

## Features

- **Image Upload**: Drag-and-drop or click to upload images
- **Real-time Preview**: See changes instantly as you adjust filters
- **Advanced Filters**:
  - Brightness adjustment
  - Contrast control
  - Saturation modification
  - Blur effect
  - Grayscale conversion
  - Sepia tone
  - Hue rotation
  - Color inversion
- **Export**: Download processed images in PNG format
- **Responsive Design**: Works seamlessly on desktop and mobile devices

## Tech Stack

- **React 18** - Modern UI library
- **TypeScript** - Type-safe development
- **Vite** - Lightning-fast build tool
- **Tailwind CSS** - Utility-first CSS framework
- **Canvas API** - Image processing

## Getting Started

### Prerequisites

- Node.js 18+ and npm

### Installation

1. Clone the repository:
```bash
git clone https://github.com/minmcho/radiant-vision-app.git
cd radiant-vision-app
```

2. Install dependencies:
```bash
npm install
```

3. Start the development server:
```bash
npm run dev
```

4. Open your browser and navigate to `http://localhost:5173`

## Development

### Available Scripts

- `npm run dev` - Start development server
- `npm run build` - Build for production
- `npm run preview` - Preview production build
- `npm run lint` - Run ESLint

### Project Structure

```
radiant-vision-app/
├── src/
│   ├── components/
│   │   ├── ImageUploader.tsx    # Image upload component
│   │   ├── ImageEditor.tsx      # Main editor with canvas
│   │   └── ImageFilters.tsx     # Filter controls
│   ├── App.tsx                  # Main app component
│   ├── main.tsx                 # Entry point
│   └── index.css                # Global styles
├── public/                      # Static assets
├── index.html                   # HTML template
└── package.json                 # Dependencies
```

## Usage

1. **Upload an Image**: Click the upload area or drag and drop an image file
2. **Apply Filters**: Use the sliders to adjust various image properties
3. **Download**: Click the "Download" button to save your edited image
4. **Reset**: Use "Reset All" to restore default filter values or "New Image" to start over

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## License

MIT License - feel free to use this project for personal or commercial purposes.

## Author

Built with care by the Radiant Vision team
