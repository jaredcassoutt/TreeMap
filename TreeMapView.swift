import SwiftUI

// MARK: - CornerStyle Enum
public enum CornerStyle: String {
    case squared = "SQUARED"
    case rounded = "ROUNDED"
}

// MARK: - Container
class Container {
    var xOffset: Double
    var yOffset: Double
    var height: Double
    var width: Double

    init(xOff: Double, yOff: Double, h: Double, w: Double) {
        self.xOffset = xOff
        self.yOffset = yOff
        self.height = h
        self.width = w
    }

    func shortestEdge() -> Double {
        min(height, width)
    }

    func getCoordinates(row: [Double]) -> [[Double]] {
        var coordinates = [[Double]]()
        var subXOffset = xOffset
        var subYOffset = yOffset
        let areaWidth = row.reduce(0, +) / height
        let areaHeight = row.reduce(0, +) / width

        if width >= height {
            for value in row {
                coordinates.append([
                    subXOffset,
                    subYOffset,
                    subXOffset + areaWidth,
                    subYOffset + value / areaWidth
                ])
                subYOffset += value / areaWidth
            }
        } else {
            for value in row {
                coordinates.append([
                    subXOffset,
                    subYOffset,
                    subXOffset + (value / areaHeight),
                    subYOffset + areaHeight
                ])
                subXOffset += (value / areaHeight)
            }
        }
        return coordinates
    }

    func cutArea(area: Double) -> Container {
        if width >= height {
            let areaWidth = area / height
            let newWidth = width - areaWidth
            return Container(xOff: xOffset + areaWidth, yOff: yOffset, h: height, w: newWidth)
        } else {
            let areaHeight = area / width
            let newHeight = height - areaHeight
            return Container(xOff: xOffset, yOff: yOffset + areaHeight, h: newHeight, w: width)
        }
    }
}

// MARK: - TreeMap Layout Engine
public class TreeMap {
    var stack: [[Double]] = []

    /// Normalize data so that the areas sum to width * height.
    private func normalize(data: [Double], area: Double) -> [Double] {
        let sum = data.reduce(0, +)
        guard sum != 0 else { return data }
        let multiplier = area / sum
        return data.map { $0 * multiplier }
    }

    /// Main entry point: compute coordinate rectangles for each data point.
    public func treemapCoords(data: [Double],
                              width: Double,
                              height: Double,
                              xOffset: Double,
                              yOffset: Double) -> [[Double]] {

        let newData = normalize(data: data, area: width * height)
        let container = Container(xOff: xOffset, yOff: yOffset, h: height, w: width)
        stack.removeAll()
        _ = squarify(d: newData, cRow: [], container: container)
        return stack
    }

    private func squarify(d: [Double], cRow: [Double], container: Container) -> [[Double]] {
        var data = d
        var currentRow = cRow

        if data.isEmpty {
            stack += container.getCoordinates(row: currentRow)
            return stack
        }

        let length = container.shortestEdge()
        let nextValue = data[0]

        if improvesRatio(currentRow: currentRow, nextNode: nextValue, length: length) {
            currentRow.append(nextValue)
            data.remove(at: 0)
            return squarify(d: data, cRow: currentRow, container: container)
        } else {
            stack += container.getCoordinates(row: currentRow)
            let usedArea = currentRow.reduce(0, +)
            let newContainer = container.cutArea(area: usedArea)
            return squarify(d: data, cRow: [], container: newContainer)
        }
    }

    private func improvesRatio(currentRow: [Double], nextNode: Double, length: Double) -> Bool {
        if currentRow.isEmpty { return true }
        var newRow = currentRow
        newRow.append(nextNode)

        let currentRatio = calculateRatio(row: currentRow, length: length)
        let newRatio = calculateRatio(row: newRow, length: length)
        return currentRatio >= newRatio
    }

    /// Calculate the "squareness" ratio.
    private func calculateRatio(row: [Double], length: Double) -> Double {
        guard let minValue = row.min(),
              let maxValue = row.max() else { return 0 }

        let sum = row.reduce(0, +)
        let ratio1 = (length * length * maxValue) / (sum * sum)
        let ratio2 = (sum * sum) / (length * length * minValue)
        return max(ratio1, ratio2)
    }
}

// MARK: - View Model
public struct TreeMapViewModel {
    /// Nested struct for individual tree map items.
    public struct TreeMapItem {
        let sizeValue: Double
        let colorValue: Double
        let title: String?
        let imageURL: String?
        let actionParam: String
    }

    public let items: [TreeMapItem]
    public let negativeColor: Color
    public let neutralColor: Color
    public let positiveColor: Color
    public let spacing: CGFloat
    public let cornerStyle: CornerStyle
    public let minCellSize: CGFloat

    public init(items: [TreeMapItem],
                negativeColor: Color,
                neutralColor: Color,
                positiveColor: Color,
                spacing: CGFloat = 0,
                cornerStyle: CornerStyle,
                minCellSize: CGFloat = 8) {
        self.items = items
        self.negativeColor = negativeColor
        self.neutralColor = neutralColor
        self.positiveColor = positiveColor
        self.spacing = spacing
        self.cornerStyle = cornerStyle
        self.minCellSize = minCellSize
    }
}

// MARK: - TreeMapView
public struct TreeMapView: View {
    let viewModel: TreeMapViewModel
    let onItemTap: (String) -> Void

    private let treeMap = TreeMap()

    public var body: some View {
        GeometryReader { geo in
            let sizes = viewModel.items.map { abs($0.sizeValue) }

            let coords = treeMap.treemapCoords(
                data: sizes,
                width: geo.size.width,
                height: geo.size.height,
                xOffset: 0,
                yOffset: 0
            )

            let spacing = viewModel.spacing
            let minCellSize = viewModel.minCellSize
            let cornerRadius = viewModel.cornerStyle == .rounded ? getCornerRadius(for: coords, spacing: spacing) : 0

            let maxAbsColorValue = (viewModel.items.map { abs($0.colorValue) }.max() ?? 0)

            ZStack {
                ForEach(0 ..< coords.count, id: \.self) { i in
                    let rect = coords[i]
                    let item = viewModel.items[i]

                    let x1 = rect[0]
                    let y1 = rect[1]
                    let x2 = rect[2]
                    let y2 = rect[3]

                    let adjX1 = x1 + spacing / 2
                    let adjY1 = y1 + spacing / 2
                    let adjX2 = x2 - spacing / 2
                    let adjY2 = y2 - spacing / 2

                    let rawWidth = adjX2 - adjX1
                    let rawHeight = adjY2 - adjY1

                    let finalWidth = max(rawWidth, minCellSize)
                    let finalHeight = max(rawHeight, minCellSize)

                    let signValue = item.colorValue
                    let alpha = (maxAbsColorValue == 0) ? 1 : max(0.1, abs(signValue) / maxAbsColorValue)
                    let baseColor: any ShapeStyle = (signValue < 0) ? viewModel.negativeColor : viewModel.positiveColor

                    Button {
                        onItemTap(item.actionParam)
                    } label: {
                        ZStack {
                            // Neutral background.
                            Rectangle()
                                .foregroundStyle(viewModel.neutralColor)
                                .cornerRadius(cornerRadius)
                            // Overlay color.
                            Rectangle()
                                .foregroundStyle(AnyShapeStyle(baseColor))
                                .opacity(signValue == 0 ? 1 : Double(alpha))
                                .cornerRadius(cornerRadius)

                            // Display image (if available) or fallback text.
                            if let urlString = item.imageURL,
                               let url = URL(string: urlString) {
                                AsyncImage(url: url) { phase in
                                    switch phase {
                                    case .empty:
                                        ProgressView()
                                    case .success(let image):
                                        image
                                            .resizable()
                                            .scaledToFit()
                                            .frame(width: finalWidth * 0.8, height: finalHeight * 0.8)
                                            .shadow(radius: 4)
                                    case .failure(_):
                                        Text(item.title ?? "")
                                            .font(.caption)
                                            .bold()
                                            .foregroundColor(.white)
                                            .shadow(radius: 1)
                                    @unknown default:
                                        EmptyView()
                                    }
                                }
                            } else {
                                Text(item.title ?? "")
                                    .font(.caption)
                                    .bold()
                                    .foregroundColor(.white)
                                    .shadow(radius: 1)
                            }
                        }
                        .frame(width: finalWidth, height: finalHeight)
                    }
                    // Position the button in the center of its rectangle.
                    .position(
                        x: adjX1 + finalWidth / 2,
                        y: adjY1 + finalHeight / 2
                    )
                    .buttonStyle(.plain)
                }
            }
        }
    }

    /// Calculate a consistent corner radius from the smallest rectangle dimension.
    private func getCornerRadius(for coordinates: [[Double]], spacing: CGFloat) -> CGFloat {
        var sizes = [Double]()
        for rect in coordinates {
            var x1 = rect[0]
            var y1 = rect[1]
            var x2 = rect[2]
            var y2 = rect[3]
            x1 += spacing / 2
            y1 += spacing / 2
            x2 -= spacing / 2
            y2 -= spacing / 2

            sizes.append(x2 - x1)
            sizes.append(y2 - y1)
        }
        let minDimension = sizes.min() ?? 0
        return CGFloat(minDimension / 6)
    }
}
