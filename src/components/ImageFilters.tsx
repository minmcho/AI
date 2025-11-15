import { FilterSettings } from './ImageEditor'

interface ImageFiltersProps {
  filters: FilterSettings
  onFilterChange: (filterName: keyof FilterSettings, value: number) => void
  onReset: () => void
}

interface FilterControl {
  name: keyof FilterSettings
  label: string
  min: number
  max: number
  step: number
  unit: string
}

const filterControls: FilterControl[] = [
  { name: 'brightness', label: 'Brightness', min: 0, max: 200, step: 1, unit: '%' },
  { name: 'contrast', label: 'Contrast', min: 0, max: 200, step: 1, unit: '%' },
  { name: 'saturation', label: 'Saturation', min: 0, max: 200, step: 1, unit: '%' },
  { name: 'blur', label: 'Blur', min: 0, max: 10, step: 0.1, unit: 'px' },
  { name: 'grayscale', label: 'Grayscale', min: 0, max: 100, step: 1, unit: '%' },
  { name: 'sepia', label: 'Sepia', min: 0, max: 100, step: 1, unit: '%' },
  { name: 'hueRotate', label: 'Hue Rotate', min: 0, max: 360, step: 1, unit: '°' },
  { name: 'invert', label: 'Invert', min: 0, max: 100, step: 1, unit: '%' },
]

export default function ImageFilters({
  filters,
  onFilterChange,
  onReset,
}: ImageFiltersProps) {
  return (
    <div className="bg-white bg-opacity-10 backdrop-blur-sm rounded-lg p-6">
      <div className="flex justify-between items-center mb-6">
        <h2 className="text-2xl font-bold text-white">Filters</h2>
        <button
          onClick={onReset}
          className="bg-blue-600 hover:bg-blue-700 text-white font-semibold py-2 px-4 rounded transition-colors text-sm"
        >
          Reset All
        </button>
      </div>

      <div className="space-y-6">
        {filterControls.map((control) => (
          <div key={control.name}>
            <div className="flex justify-between items-center mb-2">
              <label className="text-white font-medium">
                {control.label}
              </label>
              <span className="text-blue-200 font-mono text-sm">
                {filters[control.name]}{control.unit}
              </span>
            </div>
            <input
              type="range"
              min={control.min}
              max={control.max}
              step={control.step}
              value={filters[control.name]}
              onChange={(e) =>
                onFilterChange(control.name, parseFloat(e.target.value))
              }
              className="w-full h-2 bg-blue-900 rounded-lg appearance-none cursor-pointer accent-blue-500"
            />
          </div>
        ))}
      </div>
    </div>
  )
}
