# CLAUDE.md - AI Assistant Guide for Radiant Vision App

## Project Overview

**Radiant Vision** is a modern, web-based image processing application that allows users to upload images and apply real-time filters using the Canvas API. The application is built with React 18, TypeScript, Vite, and Tailwind CSS, focusing on a responsive and intuitive user experience.

### Core Functionality
- Image upload via drag-and-drop or file selection
- Real-time filter preview with Canvas API
- 8 adjustable filters: brightness, contrast, saturation, blur, grayscale, sepia, hue rotation, and color inversion
- Download processed images as PNG
- Reset functionality for filters and image selection

---

## Codebase Structure

```
radiant-vision-app/
├── src/
│   ├── components/
│   │   ├── ImageUploader.tsx    # Handles image upload (drag-drop + file input)
│   │   ├── ImageEditor.tsx      # Main editor with canvas rendering
│   │   └── ImageFilters.tsx     # Filter controls UI (sliders)
│   ├── App.tsx                  # Root component, manages app state
│   ├── main.tsx                 # Application entry point
│   ├── App.css                  # Component-specific styles
│   └── index.css                # Global styles + Tailwind directives
├── public/                      # Static assets
├── index.html                   # HTML template
├── package.json                 # Dependencies and scripts
├── tsconfig.json                # TypeScript configuration (strict mode)
├── tsconfig.node.json           # TypeScript config for Vite
├── vite.config.ts               # Vite build configuration
├── tailwind.config.js           # Tailwind CSS configuration
├── postcss.config.js            # PostCSS configuration
├── LICENSE                      # MIT License
└── README.md                    # User-facing documentation
```

---

## Tech Stack

| Technology | Version | Purpose |
|------------|---------|---------|
| **React** | 18.2.0 | UI library with hooks-based architecture |
| **TypeScript** | 5.2.2 | Type-safe development with strict mode |
| **Vite** | 5.0.8 | Fast build tool and dev server |
| **Tailwind CSS** | 3.3.6 | Utility-first CSS framework |
| **Canvas API** | Native | Image processing and filter application |
| **ESLint** | 8.55.0 | Code linting with TypeScript support |

### Dev Dependencies
- `@vitejs/plugin-react` - React support for Vite
- `@typescript-eslint/*` - TypeScript ESLint plugins
- `eslint-plugin-react-hooks` - React hooks linting rules
- `autoprefixer` & `postcss` - CSS processing for Tailwind

---

## Architecture & Data Flow

### Component Hierarchy
```
App (root)
├── ImageUploader (when no image selected)
│   └── File input + drag-drop zone
└── ImageEditor (when image selected)
    ├── Canvas (preview)
    └── ImageFilters (controls)
```

### State Management
- **App.tsx**: Manages global state (`image: string | null`)
- **ImageEditor.tsx**: Manages filter state (`FilterSettings` object)
- **Unidirectional data flow**: Props down, callbacks up

### Filter Application Flow
1. User uploads image → `App` stores base64 image data
2. `ImageEditor` receives image, initializes canvas
3. User adjusts filter → `ImageFilters` calls `onFilterChange`
4. `ImageEditor` updates filter state → triggers re-render
5. Canvas applies CSS filters via `ctx.filter` property
6. Real-time preview updates immediately

---

## Component Details

### 1. App.tsx (Root Component)
**Location**: `src/App.tsx:1-45`

**Responsibilities**:
- Global state management (`image` state)
- Conditional rendering (uploader vs editor)
- Layout and header/footer

**Key State**:
```typescript
const [image, setImage] = useState<string | null>(null)
```

**Important Patterns**:
- Uses gradient background: `bg-gradient-to-br from-purple-900 via-blue-900 to-indigo-900`
- Container with responsive padding: `container mx-auto px-4 py-8`

---

### 2. ImageUploader.tsx
**Location**: `src/components/ImageUploader.tsx:1-85`

**Responsibilities**:
- Handle file upload via `<input type="file">`
- Handle drag-and-drop events
- Convert images to base64 using FileReader API
- Validate file types (must start with `image/`)

**Key Functions**:
- `handleFileChange` (line 8-21): Processes file input changes
- `handleDrop` (line 23-37): Processes dropped files
- `handleDragOver` (line 39-41): Prevents default drag behavior

**Usage Pattern**:
```typescript
<ImageUploader onImageUpload={(imageData: string) => void} />
```

**Styling Notes**:
- Dashed border: `border-4 border-dashed border-blue-400`
- Glass morphism: `bg-white bg-opacity-10 backdrop-blur-sm`
- Hover effect: `hover:bg-opacity-20`

---

### 3. ImageEditor.tsx
**Location**: `src/components/ImageEditor.tsx:1-137`

**Responsibilities**:
- Render canvas and apply filters
- Manage filter state (8 different filters)
- Handle image download
- Coordinate with ImageFilters component

**Key Interfaces**:
```typescript
interface FilterSettings {
  brightness: number    // 0-200 (%)
  contrast: number      // 0-200 (%)
  saturation: number    // 0-200 (%)
  blur: number          // 0-10 (px)
  grayscale: number     // 0-100 (%)
  sepia: number         // 0-100 (%)
  hueRotate: number     // 0-360 (deg)
  invert: number        // 0-100 (%)
}
```

**Critical Functions**:
- `applyFilters` (line 49-63): Applies CSS filter string to canvas context
- `handleDownload` (line 85-93): Exports canvas as PNG using `toDataURL()`
- `handleReset` (line 72-83): Resets all filters to default values

**Canvas Implementation**:
- Uses `useRef<HTMLCanvasElement>` for canvas reference
- `useEffect` hook triggers on image/filter changes
- Canvas size matches source image dimensions
- Filter string combines all active filters

**Default Filter Values**:
- brightness: 100%, contrast: 100%, saturation: 100%
- blur: 0px, grayscale: 0%, sepia: 0%
- hueRotate: 0deg, invert: 0%

---

### 4. ImageFilters.tsx
**Location**: `src/components/ImageFilters.tsx:1-74`

**Responsibilities**:
- Render slider controls for each filter
- Display current filter values with units
- Provide "Reset All" button

**Key Data Structure**:
```typescript
interface FilterControl {
  name: keyof FilterSettings
  label: string
  min: number
  max: number
  step: number
  unit: string
}
```

**Filter Controls Array** (line 18-27):
Defines configuration for all 8 filters including ranges and step values.

**Usage Pattern**:
```typescript
<ImageFilters
  filters={filters}
  onFilterChange={(name, value) => void}
  onReset={() => void}
/>
```

**Styling Notes**:
- Range input styling: `accent-blue-500` for modern slider color
- Value display: `font-mono text-sm` for numeric values
- Responsive spacing: `space-y-6` between controls

---

## Development Workflows

### Available Scripts

```bash
npm run dev      # Start development server (http://localhost:5173)
npm run build    # Type-check + production build
npm run preview  # Preview production build locally
npm run lint     # Run ESLint on .ts and .tsx files
```

### Build Process
1. TypeScript compilation (`tsc`)
2. Vite bundling with React plugin
3. Tailwind CSS processing via PostCSS
4. Output to `dist/` directory

### Development Server
- Vite dev server with HMR (Hot Module Replacement)
- Default port: 5173
- Fast refresh for React components

---

## Key Conventions

### TypeScript Guidelines

1. **Strict Mode Enabled** (tsconfig.json:16)
   - All strict type checking options active
   - `noUnusedLocals` and `noUnusedParameters` enabled
   - `noFallthroughCasesInSwitch` enabled

2. **Interface Naming**
   - Props interfaces: `ComponentNameProps` pattern
   - Example: `ImageUploaderProps`, `ImageEditorProps`

3. **Type Safety**
   - All component props are typed
   - Event handlers have explicit types: `React.ChangeEvent<HTMLInputElement>`
   - Canvas operations use proper context types: `CanvasRenderingContext2D`

4. **No Implicit Any**
   - All variables and parameters must have explicit or inferred types
   - File reader results cast appropriately: `e.target?.result as string`

### React Patterns

1. **Hooks Usage**
   - `useState` for local component state
   - `useRef` for DOM references (canvas)
   - `useEffect` for side effects (canvas rendering)
   - `useCallback` for memoized event handlers

2. **Component Structure**
   - Functional components only (no class components)
   - Props interfaces defined at top of file
   - Event handlers use arrow functions
   - JSX in return statement

3. **State Management**
   - Lift state to lowest common ancestor
   - Callback props for child-to-parent communication
   - Immutable state updates using spread operator

4. **Event Handlers**
   - Prefix with `handle`: `handleFileChange`, `handleDrop`
   - Use `useCallback` for handlers passed to child components
   - Type event parameters explicitly

### Styling Conventions

1. **Tailwind Utility Classes**
   - Mobile-first responsive design
   - Consistent color palette: blue, purple, indigo variants
   - Glass morphism pattern: `bg-white bg-opacity-10 backdrop-blur-sm`

2. **Color Scheme**
   - Background: Purple/Blue/Indigo gradient
   - Primary actions: Blue (600-700)
   - Success: Green (600-700)
   - Danger: Red (600-700)
   - Text: White with varying opacity

3. **Layout Patterns**
   - Grid system: `grid grid-cols-1 lg:grid-cols-3`
   - Flexbox for alignment: `flex justify-between items-center`
   - Container: `container mx-auto px-4`
   - Spacing: Consistent use of `space-y-*` and `gap-*`

4. **Responsive Design**
   - Breakpoints: `lg:` prefix for large screens
   - Mobile-first approach
   - Max widths for content: `max-w-2xl`, `max-w-7xl`

---

## Canvas API Usage

### Image Processing Pipeline

1. **Image Loading**
   ```typescript
   const img = new Image()
   img.onload = () => { /* render */ }
   img.src = imageDataBase64
   ```

2. **Canvas Sizing**
   - Canvas dimensions match source image
   - Preserves aspect ratio
   - `canvas.width = img.width`, `canvas.height = img.height`

3. **Filter Application**
   - Uses CSS filter property on canvas context
   - Multiple filters combined in single string
   - Format: `brightness(100%) contrast(100%) ...`

4. **Export**
   - `canvas.toDataURL()` converts to base64 PNG
   - Creates temporary `<a>` element for download
   - Filename: `radiant-vision-edited.png`

### Canvas Context Filter String
**Location**: `src/components/ImageEditor.tsx:50-59`

All filters are applied simultaneously via the `ctx.filter` property. The string format follows CSS filter syntax.

---

## Common AI Assistant Tasks

### Adding a New Filter

1. **Update FilterSettings interface** in `ImageEditor.tsx:9-18`
   ```typescript
   interface FilterSettings {
     // ... existing filters
     newFilter: number
   }
   ```

2. **Add default value** in `ImageEditor.tsx:22-31` and `handleReset` function

3. **Update filter string** in `applyFilters` function (line 50-59)

4. **Add filter control** to `filterControls` array in `ImageFilters.tsx:18-27`
   ```typescript
   { name: 'newFilter', label: 'New Filter', min: 0, max: 100, step: 1, unit: '%' }
   ```

### Modifying UI Layout

- **Main layout**: `App.tsx:18-42`
- **Editor grid**: `ImageEditor.tsx:96-134` (2-column on large screens)
- **Filter panel**: `ImageFilters.tsx:34-72`

### Adjusting Filter Ranges

Modify the `filterControls` array in `ImageFilters.tsx:18-27`. Each entry defines min, max, step, and unit.

### Changing Export Format

Modify `handleDownload` in `ImageEditor.tsx:85-93`. Replace `toDataURL()` with `toDataURL('image/jpeg', quality)` for JPEG export.

### Adding File Type Validation

Update validation in `ImageUploader.tsx:11` and `ImageUploader.tsx:27`. Current check: `file.type.startsWith('image/')`.

---

## Code Quality & Linting

### ESLint Configuration
- Parser: `@typescript-eslint/parser`
- Plugins: TypeScript, React Hooks, React Refresh
- Max warnings: 0 (CI will fail on warnings)

### Type Checking
- Run `tsc` before build (part of build script)
- Strict mode catches most type errors
- No type errors allowed in production build

### Best Practices
- Use TypeScript strict mode features
- Avoid `any` type
- Memoize callbacks with `useCallback`
- Clean up effects with return functions (if applicable)
- Follow React hooks rules (ESLint enforces)

---

## File Modification Guidelines for AI Assistants

### When Adding Features

1. **Check existing patterns first**
   - Review similar components for consistency
   - Match existing TypeScript interfaces
   - Follow established naming conventions

2. **Update related files together**
   - If adding a filter, update both `ImageEditor.tsx` AND `ImageFilters.tsx`
   - Maintain type consistency across files

3. **Preserve existing functionality**
   - Don't break current filter system
   - Maintain backward compatibility
   - Test all existing features after changes

### When Refactoring

1. **Maintain type safety**
   - Don't loosen TypeScript strictness
   - Update all type definitions
   - Ensure no `any` types introduced

2. **Keep component boundaries clear**
   - `App`: Global state only
   - `ImageEditor`: Filter state and canvas logic
   - `ImageFilters`: UI controls only
   - `ImageUploader`: File handling only

3. **Preserve styling consistency**
   - Use existing Tailwind color scheme
   - Match current spacing/sizing patterns
   - Maintain glass morphism aesthetic

### When Fixing Bugs

1. **Check TypeScript errors first**
   ```bash
   npm run build  # Runs tsc
   ```

2. **Verify ESLint compliance**
   ```bash
   npm run lint
   ```

3. **Test in development mode**
   ```bash
   npm run dev
   ```

4. **Common issues to check**:
   - Canvas context null checks
   - FileReader event handling
   - Image load event timing
   - Filter value bounds

### Important: Don't Break These

1. **Canvas rendering logic** in `ImageEditor.tsx:33-63`
   - Critical for image processing
   - Handles filter application

2. **File upload validation** in `ImageUploader.tsx:11,27`
   - Security-relevant code
   - Prevents invalid file types

3. **Type interfaces** (FilterSettings, props interfaces)
   - Breaking changes affect multiple files
   - Always update all usages

4. **Build configuration**
   - `vite.config.ts`, `tsconfig.json`, `tailwind.config.js`
   - Changes can break entire build

---

## Testing Strategy

### Manual Testing Checklist
- [ ] Upload image via file picker
- [ ] Upload image via drag-and-drop
- [ ] Adjust all 8 filters individually
- [ ] Combine multiple filters
- [ ] Reset filters (individual button)
- [ ] Download processed image
- [ ] Load new image (reset button)
- [ ] Verify responsive layout on mobile/desktop

### Edge Cases to Consider
- Very large images (>5000px)
- Unsupported file types
- Corrupted image files
- Mobile touch interactions
- Safari browser compatibility (Canvas API)

---

## Performance Considerations

1. **Canvas Re-rendering**
   - Triggered on every filter change
   - Uses `useEffect` dependency array: `[image, filters]`
   - Consider debouncing for very large images

2. **Memory Management**
   - Canvas maintains full-resolution image
   - Large images may consume significant memory
   - Consider max dimension limits for production

3. **Bundle Size**
   - Current setup is minimal (React + Canvas API only)
   - No heavy image processing libraries
   - Vite optimizes production bundle

---

## Browser Compatibility

### Required Features
- Canvas API with filter support
- FileReader API
- Drag and drop API
- CSS backdrop-filter (for glass morphism)

### Tested Browsers
- Chrome/Edge (Chromium-based): Full support
- Firefox: Full support
- Safari: Full support (check backdrop-filter)

### Potential Issues
- Older browsers may not support `ctx.filter` property
- IE11: Not supported (uses modern ES features)

---

## Future Enhancement Ideas

### Features to Consider
- Multiple image layers
- Custom filter presets (save/load)
- Crop and rotate tools
- Undo/redo functionality
- Color picker for tinting
- Text overlay support
- Export to multiple formats (JPEG, WebP)
- Batch processing

### Architecture Improvements
- State management library (Redux/Zustand) if complexity grows
- Web Workers for heavy processing
- Service Worker for offline support
- Image optimization before download

### UI Enhancements
- Before/after slider
- Filter previews (thumbnails)
- Keyboard shortcuts
- History panel
- Mobile gesture support (pinch-to-zoom)

---

## Quick Reference

### Important File Locations
| File | Purpose | Key Lines |
|------|---------|-----------|
| `src/App.tsx` | Root component | State: 7, Render logic: 30-34 |
| `src/components/ImageEditor.tsx` | Canvas logic | Filter application: 49-63 |
| `src/components/ImageFilters.tsx` | Filter UI | Controls config: 18-27 |
| `src/components/ImageUploader.tsx` | File upload | File handling: 8-37 |
| `package.json` | Dependencies | Scripts: 6-11 |
| `tsconfig.json` | TS config | Strict mode: 16-19 |

### Key Constants
- Default port: 5173
- Download filename: `radiant-vision-edited.png`
- Canvas max height: 600px (container)
- Filter count: 8
- Supported formats: All image/* MIME types

### Dependencies to Never Remove
- react, react-dom (core)
- @vitejs/plugin-react (build)
- typescript (type checking)
- tailwindcss, autoprefixer, postcss (styling)

---

## Questions to Ask When Uncertain

1. **Before adding dependencies**: "Is this feature achievable with Canvas API or existing dependencies?"
2. **Before major refactoring**: "Will this maintain backward compatibility?"
3. **Before changing build config**: "Do I understand the impact on the build pipeline?"
4. **Before modifying types**: "Have I updated all files that use this type?"
5. **Before deploying**: "Have I run `npm run build` and `npm run lint`?"

---

## Contact & Resources

- **Repository**: Based on initial commit message (check git remote)
- **License**: MIT (see LICENSE file)
- **React Docs**: https://react.dev
- **TypeScript Docs**: https://www.typescriptlang.org/docs
- **Vite Docs**: https://vitejs.dev
- **Tailwind CSS**: https://tailwindcss.com/docs
- **Canvas API**: https://developer.mozilla.org/en-US/docs/Web/API/Canvas_API

---

**Last Updated**: 2025-11-16
**Version**: 1.0.0
**Maintained by**: AI assistants working on this repository

---

## Summary for AI Assistants

This is a **small, focused codebase** with clear separation of concerns:

- **3 main components** (Uploader, Editor, Filters)
- **Simple state flow** (App → ImageEditor → ImageFilters)
- **Canvas-based processing** (no external image libraries)
- **TypeScript strict mode** (type safety enforced)
- **Tailwind styling** (utility classes, no custom CSS needed)

**Before making changes**: Read the relevant component file, understand the data flow, maintain type safety, and follow existing patterns. The codebase is intentionally simple—keep it that way.
