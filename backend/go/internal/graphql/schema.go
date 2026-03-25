package graphql

// Schema is the GraphQL SDL for the CargoTrack platform.
const Schema = `
  scalar Time
  scalar UUID
  scalar JSON

  # ── Enums ──────────────────────────────────────────────────

  enum ShipmentStatus {
    PENDING
    IN_TRANSIT
    AT_CUSTOMS
    ARRIVED
    DELIVERED
    EXCEPTION
    CANCELLED
  }

  enum Priority {
    LOW
    STANDARD
    HIGH
    CRITICAL
  }

  enum LocationType {
    WAREHOUSE
    PORT
    DEPOT
    HUB
    TERMINAL
    CUSTOM
  }

  enum MovementType {
    INBOUND
    OUTBOUND
    TRANSFER
    ADJUSTMENT
    COUNT
  }

  enum AlertSeverity {
    INFO
    WARNING
    ERROR
    CRITICAL
  }

  enum DefectSeverity {
    LOW
    MEDIUM
    HIGH
    CRITICAL
  }

  # ── Types ───────────────────────────────────────────────────

  type Department {
    id:         UUID!
    name:       String!
    code:       String!
    parent:     Department
    createdAt:  Time!
  }

  type Region {
    id:        UUID!
    name:      String!
    code:      String!
    country:   String!
    timezone:  String!
    locations: [Location!]!
  }

  type Location {
    id:           UUID!
    name:         String!
    code:         String!
    region:       Region!
    department:   Department
    address:      String
    latitude:     Float
    longitude:    Float
    locationType: LocationType!
    inventory:    [InventoryItem!]!
  }

  type Unit {
    id:         UUID!
    name:       String!
    code:       String!
    unitType:   String!
    tareKg:     Float
    maxLoadKg:  Float
    volumeM3:   Float
  }

  type Shipment {
    id:               UUID!
    trackingNumber:   String!
    status:           ShipmentStatus!
    priority:         Priority!
    origin:           Location!
    destination:      Location!
    department:       Department
    carrier:          String
    serviceType:      String
    estimatedArrival: Time
    actualArrival:    Time
    totalWeightKg:    Float
    totalVolumeM3:    Float
    notes:            String
    cargoItems:       [CargoItem!]!
    events:           [TrackingEvent!]!
    alerts:           [Alert!]!
    createdAt:        Time!
    updatedAt:        Time!
  }

  type CargoItem {
    id:              UUID!
    shipment:        Shipment!
    unit:            Unit
    sku:             String
    description:     String!
    quantity:        Int!
    weightKg:        Float
    volumeM3:        Float
    valueUsd:        Float
    hsCode:          String
    hazmatClass:     String
    category:        String
    subCategory:     String
    clusterId:       Int
    defectScore:     Float
    defects:         [DefectDetection!]!
    createdAt:       Time!
  }

  type TrackingEvent {
    id:           UUID!
    shipment:     Shipment!
    eventType:    String!
    location:     Location
    locationName: String
    latitude:     Float
    longitude:    Float
    description:  String
    occurredAt:   Time!
    metadata:     JSON
  }

  type InventoryItem {
    id:            UUID!
    location:      Location!
    department:    Department
    sku:           String!
    description:   String
    quantity:      Int!
    unit:          Unit
    reorderPoint:  Int
    maxStock:      Int
    binLocation:   String
    category:      String
    subCategory:   String
    clusterId:     Int
    movements:     [InventoryMovement!]!
    lastCountedAt: Time
    updatedAt:     Time!
  }

  type InventoryMovement {
    id:            UUID!
    movementType:  MovementType!
    quantityDelta: Int!
    quantityAfter: Int!
    notes:         String
    occurredAt:    Time!
  }

  type DefectDetection {
    id:             UUID!
    cargoItem:      CargoItem
    inventoryItem:  InventoryItem
    location:       Location
    imageUrl:       String
    defectType:     String
    severity:       DefectSeverity
    confidence:     Float
    boundingBoxes:  JSON
    modelVersion:   String
    reasoning:      String
    actionTaken:    String
    resolvedAt:     Time
    createdAt:      Time!
  }

  type Alert {
    id:           UUID!
    alertType:    String!
    severity:     AlertSeverity!
    title:        String!
    message:      String!
    entityType:   String
    entityId:     UUID
    location:     Location
    department:   Department
    acknowledged: Boolean!
    createdAt:    Time!
  }

  type ClusteringResult {
    runId:          UUID!
    runType:        String!
    algorithm:      String!
    numClusters:    Int!
    silhouetteScore: Float
    clusters:       [ClusterLabel!]!
  }

  type ClusterLabel {
    clusterId: Int!
    name:      String!
    size:      Int!
  }

  type DashboardStats {
    activeShipments:   Int!
    deliveredToday:    Int!
    pendingAlerts:     Int!
    defectsDetected:   Int!
    lowStockItems:     Int!
    shipmentsPerRegion:[RegionStat!]!
  }

  type RegionStat {
    region: String!
    count:  Int!
  }

  # ── Inputs ──────────────────────────────────────────────────

  input CreateShipmentInput {
    originId:         UUID!
    destinationId:    UUID!
    departmentId:     UUID
    carrier:          String
    serviceType:      String
    priority:         Priority
    estimatedArrival: Time
    notes:            String
  }

  input UpdateShipmentStatusInput {
    shipmentId:  UUID!
    status:      ShipmentStatus!
    locationId:  UUID
    description: String
  }

  input AddCargoItemInput {
    shipmentId:  UUID!
    unitId:      UUID
    sku:         String
    description: String!
    quantity:    Int!
    weightKg:    Float
    volumeM3:    Float
    valueUsd:    Float
    hsCode:      String
    hazmatClass: String
  }

  input AdjustInventoryInput {
    locationId:    UUID!
    sku:           String!
    quantityDelta: Int!
    movementType:  MovementType!
    notes:         String
  }

  input ShipmentFilter {
    status:       ShipmentStatus
    priority:     Priority
    departmentId: UUID
    originId:     UUID
    destinationId:UUID
    limit:        Int
    offset:       Int
  }

  input InventoryFilter {
    locationId:   UUID
    departmentId: UUID
    belowReorder: Boolean
    clusterId:    Int
    limit:        Int
    offset:       Int
  }

  # ── Query / Mutation / Subscription ─────────────────────────

  type Query {
    # Organisational
    departments:          [Department!]!
    regions:              [Region!]!
    locations(regionId: UUID): [Location!]!

    # Shipments
    shipments(filter: ShipmentFilter): [Shipment!]!
    shipment(id: UUID!):               Shipment
    shipmentByTracking(trackingNumber: String!): Shipment

    # Inventory
    inventory(filter: InventoryFilter): [InventoryItem!]!
    inventoryItem(id: UUID!):           InventoryItem

    # Defects
    defects(locationId: UUID, severity: DefectSeverity, limit: Int): [DefectDetection!]!
    defect(id: UUID!): DefectDetection

    # Alerts
    alerts(departmentId: UUID, severity: AlertSeverity, unacknowledgedOnly: Boolean): [Alert!]!

    # AI / ML
    similarItems(itemId: UUID!, limit: Int):     [CargoItem!]!
    latestClustering(runType: String!):           ClusteringResult

    # Dashboard
    dashboardStats(departmentId: UUID):           DashboardStats!
  }

  type Mutation {
    createShipment(input: CreateShipmentInput!):       Shipment!
    updateShipmentStatus(input: UpdateShipmentStatusInput!): Shipment!
    addCargoItem(input: AddCargoItemInput!):            CargoItem!
    adjustInventory(input: AdjustInventoryInput!):     InventoryItem!
    acknowledgeAlert(alertId: UUID!):                  Alert!
    resolveDefect(defectId: UUID!, action: String!):   DefectDetection!
  }

  type Subscription {
    # Real-time shipment updates for a given department / all
    shipmentUpdated(departmentId: UUID):   Shipment!
    # Real-time new tracking events
    trackingEvent(shipmentId: UUID):       TrackingEvent!
    # Real-time alerts
    newAlert(departmentId: UUID, severity: AlertSeverity): Alert!
    # Real-time defect detections
    defectDetected(locationId: UUID):      DefectDetection!
    # Inventory changes
    inventoryChanged(locationId: UUID):    InventoryItem!
  }
`
