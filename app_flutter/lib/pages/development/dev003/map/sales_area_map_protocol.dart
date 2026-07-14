/// iframe ↔ Flutter postMessage (`web/kakao_sales_area_*.html` 와 SYNC).
const String kSalesAreaMapMsgPrefix = 'yj_sa_v1|';

const String kSalesAreaOpInit = 'INIT';
const String kSalesAreaOpReady = 'READY';
const String kSalesAreaOpFilter = 'FILTER';
const String kSalesAreaOpUpdatePoints = 'UPDATE_POINTS';
const String kSalesAreaOpStats = 'STATS';
const String kSalesAreaOpSave = 'SAVE';
const String kSalesAreaOpCmd = 'CMD';
const String kSalesAreaOpViewOptions = 'VIEW_OPTIONS';
const String kSalesAreaOpUpdateGeometry = 'UPDATE_GEOMETRY';
const String kSalesAreaOpMapBounds = 'MAP_BOUNDS';
const String kSalesAreaOpAddressSelected = 'ADDRESS_SELECTED';
const String kSalesAreaOpGeometryChanged = 'GEOMETRY_CHANGED';

const String kSalesAreaCmdEditGeometry = 'EDIT_GEOMETRY';

const String kSalesAreaCmdDrawPolygon = 'DRAW_POLYGON';
const String kSalesAreaCmdDrawCircle = 'DRAW_CIRCLE';
const String kSalesAreaCmdDrawReferenceCircle = 'DRAW_REFERENCE_CIRCLE';
const String kSalesAreaCmdSearchAddress = 'SEARCH_ADDRESS';
const String kSalesAreaCmdDistanceMeasure = 'DISTANCE_MEASURE';
const String kSalesAreaCmdFinishDistanceMeasure = 'FINISH_DISTANCE_MEASURE';
const String kSalesAreaCmdRadiusMeasure = 'RADIUS_MEASURE';
const String kSalesAreaCmdClearDrawing = 'CLEAR_DRAWING';
const String kSalesAreaCmdClearMeasure = 'CLEAR_MEASURE';
const String kSalesAreaCmdSave = 'REQUEST_SAVE';
const String kSalesAreaOpSetReadOnly = 'SET_READONLY';
