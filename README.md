# SwiftUI TreeMap Heat Map

This repository contains a SwiftUI implementation of a TreeMap heat map. The code uses a squarify algorithm to break a rectangular container into sub-rectangles proportional to your data values. It supports customizable corner styles, tap actions, and can display images or text within each cell.

This was originally created for my app: [Haplo - AI Investing](https://medium.com/r/?url=https%3A%2F%2Fapps.apple.com%2Fus%2Fapp%2Fhaplo-ai-stock-screener%2Fid1568353331)

<img width="321" alt="Screenshot preview" src="https://github.com/user-attachments/assets/9c069684-9d0c-4c95-86ac-b01a2bdc626e" />

## Features

- **TreeMap Layout Engine:** Uses a squarify algorithm to create a balanced tree map.
- **Customizable Appearance:** Supports squared or rounded corners.
- **Responsive SwiftUI View:** Adapts to various screen sizes and includes tap actions.
- **Easy Integration:** Simply copy and paste the code into your project.

## Usage

1. **Add the Code:** Copy the source code from this repository into your SwiftUI project.
2. **Create Items:** Define your data as an array of `TreeMapViewModel.TreeMapItem`.
3. **Configure the ViewModel:** Initialize a `TreeMapViewModel` with your items and styling preferences.
4. **Display the View:** Use the `TreeMapView` in your SwiftUI layout and handle item taps as needed.

### Example

```swift
// Define your tree map items.
let items = [
    TreeMapViewModel.TreeMapItem(sizeValue: 100, colorValue: 0.5, title: "Item 1", imageURL: nil, actionParam: "item1"),
    TreeMapViewModel.TreeMapItem(sizeValue: 200, colorValue: -0.3, title: "Item 2", imageURL: nil, actionParam: "item2")
]

// Create the view model.
let viewModel = TreeMapViewModel(
    items: items,
    negativeColor: .red,
    neutralColor: .gray,
    positiveColor: .green,
    spacing: 2,
    cornerStyle: .rounded,
    minCellSize: 8
)

// Use the TreeMapView in your SwiftUI layout.
TreeMapView(viewModel: viewModel) { action in
    print("Tapped on \(action)")
}
```

### Installation
Simply add the provided Swift files to your SwiftUI project, import them as needed, and start building your own interactive TreeMap heat map.

### License
This project is licensed under the MIT License.
