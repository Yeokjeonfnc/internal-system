/**
 * 영업지역 검색 지도 — Flutter Web HtmlElementView( div )용.
 * postMessage 프로토콜: yj_sa_v1| (sales_area_map_protocol.dart 와 동기)
 */
(function (global) {
  const MSG_PREFIX = 'yj_sa_v1|';
  const SEOUL = { lat: 36.5, lng: 127.8 };

  /** @type {Map<string, object>} */
  const instances = new Map();
  let sdkPromise = null;
  let useClusterer = false;

  function emit(payload) {
    global.postMessage(MSG_PREFIX + JSON.stringify(payload), global.location.origin);
  }

  function formatLoadError(error) {
    if (!error) return 'KAKAO_SDK_UNKNOWN';
    if (typeof error === 'string') return error;
    if (error.message) return String(error.message);
    return 'KAKAO_SCRIPT_NETWORK';
  }

  function removeKakaoScripts() {
    global.document.querySelectorAll('script[src*="dapi.kakao.com"]').forEach((n) => n.remove());
    try {
      delete global.kakao;
    } catch (_) {
      global.kakao = undefined;
    }
    sdkPromise = null;
  }

  function loadScript(src) {
    return new Promise((resolve, reject) => {
      const script = global.document.createElement('script');
      script.type = 'text/javascript';
      script.charset = 'UTF-8';
      script.src = src;
      script.onload = () => {
        if (!(global.kakao && global.kakao.maps && typeof global.kakao.maps.load === 'function')) {
          reject(new Error('KAKAO_SDK_OBJECT_MISSING'));
          return;
        }
        resolve();
      };
      script.onerror = () => reject(new Error('KAKAO_SCRIPT_NETWORK'));
      global.document.head.appendChild(script);
    });
  }

  function mapsLoadAsync() {
    return new Promise((resolve, reject) => {
      const timer = global.setTimeout(() => reject(new Error('KAKAO_SDK_TIMEOUT')), 20000);
      global.kakao.maps.load(() => {
        global.clearTimeout(timer);
        resolve();
      });
    });
  }

  function ensureKakaoSdk(appKey) {
    const key = (appKey || '').trim()
      || global.localStorage.getItem('YJ_KAKAO_MAP_APP_KEY')
      || '';
    if (!key) return Promise.reject(new Error('KAKAO_MAP_KEY_EMPTY'));

    if (sdkPromise) return sdkPromise;

    sdkPromise = (async () => {
      if (global.kakao && global.kakao.maps) {
        await mapsLoadAsync();
        useClusterer = typeof global.kakao.maps.MarkerClusterer === 'function';
        return;
      }

      const base = 'https://dapi.kakao.com/v2/maps/sdk.js'
        + `?appkey=${encodeURIComponent(key)}&autoload=false`;
      const attempts = [
        { url: `${base}&libraries=clusterer`, clusterer: true },
        { url: base, clusterer: false },
      ];

      let lastError = new Error('KAKAO_SCRIPT_NETWORK');
      for (const attempt of attempts) {
        removeKakaoScripts();
        try {
          await loadScript(attempt.url);
          await mapsLoadAsync();
          useClusterer = attempt.clusterer
            && typeof global.kakao.maps.MarkerClusterer === 'function';
          return;
        } catch (error) {
          lastError = error instanceof Error ? error : new Error(formatLoadError(error));
        }
      }
      throw lastError;
    })();

    return sdkPromise.catch((e) => {
      sdkPromise = null;
      throw e;
    });
  }

  function countVertices(points) {
    let n = 0;
    points.forEach((p) => {
      const g = p.geometryData;
      if (!g) return;
      if (g.type === 'POLYGON' && g.paths) n += g.paths.length;
      if (g.type === 'CIRCLE') n += 1;
    });
    return n;
  }

  function escapeHtml(value) {
    return String(value).replace(/[&<>"']/g, (ch) => ({
      '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;',
    })[ch]);
  }

  function pointLabel(item) {
    return String(item.storeNm || item.zoneNm || '');
  }

  function addGeometry(inst, item, bounds) {
    const g = item.geometryData;
    if (!g) return;
    if (g.type === 'POLYGON' && g.paths && g.paths.length >= 3) {
      const path = g.paths.map((pt) => new global.kakao.maps.LatLng(Number(pt.lat), Number(pt.lng)));
      const polygon = new global.kakao.maps.Polygon({
        path,
        strokeWeight: 2,
        strokeColor: '#b4232a',
        strokeOpacity: 0.78,
        fillColor: '#e0474c',
        fillOpacity: 0.12,
      });
      polygon.setMap(inst.map);
      inst.overlays.push(polygon);
      path.forEach((pt) => bounds.extend(pt));
      return;
    }
    if (g.type === 'CIRCLE' && g.center && g.radius) {
      const circle = new global.kakao.maps.Circle({
        center: new global.kakao.maps.LatLng(Number(g.center.lat), Number(g.center.lng)),
        radius: Number(g.radius),
        strokeWeight: 2,
        strokeColor: '#b4232a',
        strokeOpacity: 0.78,
        fillColor: '#e0474c',
        fillOpacity: 0.12,
      });
      circle.setMap(inst.map);
      inst.overlays.push(circle);
      bounds.extend(circle.getBounds().getSouthWest());
      bounds.extend(circle.getBounds().getNorthEast());
    }
  }

  function clearMapObjects(inst) {
    if (inst.clusterer) {
      inst.clusterer.clear();
    } else {
      inst.markers.forEach((m) => m.setMap(null));
    }
    inst.overlays.forEach((o) => o.setMap(null));
    inst.markers = [];
    inst.overlays = [];
    if (inst.activeInfoWindow) {
      inst.activeInfoWindow.close();
      inst.activeInfoWindow = null;
    }
  }

  function openInfo(inst, position, item) {
    if (inst.activeInfoWindow) inst.activeInfoWindow.close();
    const name = item.storeNm || item.zoneNm || '';
    inst.activeInfoWindow = new global.kakao.maps.InfoWindow({
      position,
      content: `<div style="min-width:160px;padding:8px 10px;font-size:13px">`
        + `<strong>${escapeHtml(name)}</strong><br>${escapeHtml(item.zoneNm || '')}</div>`,
    });
    inst.activeInfoWindow.open(inst.map);
  }

  function renderPoints(inst) {
    const term = (inst.filterKeyword || '').trim().toLowerCase();
    const visible = term
      ? inst.apiPoints.filter((p) => pointLabel(p).toLowerCase().includes(term))
      : inst.apiPoints;
    clearMapObjects(inst);
    emit({
      op: 'STATS',
      hostId: inst.hostId,
      total: inst.apiPoints.length,
      visible: visible.length,
      vertices: countVertices(inst.apiPoints),
    });

    if (!visible.length) {
      inst.map.setCenter(new global.kakao.maps.LatLng(SEOUL.lat, SEOUL.lng));
      inst.map.setLevel(13);
      return;
    }

    const bounds = new global.kakao.maps.LatLngBounds();
    visible.forEach((item) => {
      const lat = Number(item.lat);
      const lng = Number(item.lng);
      if (!Number.isFinite(lat) || !Number.isFinite(lng)) return;
      const pos = new global.kakao.maps.LatLng(lat, lng);
      const marker = new global.kakao.maps.Marker({ position: pos, title: item.storeNm || '' });
      global.kakao.maps.event.addListener(marker, 'click', () => openInfo(inst, pos, item));
      inst.markers.push(marker);
      bounds.extend(pos);
      addGeometry(inst, item, bounds);
    });

    if (inst.clusterer) {
      inst.clusterer.addMarkers(inst.markers);
    } else {
      inst.markers.forEach((m) => m.setMap(inst.map));
    }
    inst.map.setBounds(bounds);
  }

  async function bootInstance(inst, points, appKey) {
    if (inst.booted) return;
    try {
      await ensureKakaoSdk(appKey);
      inst.apiPoints = (points || []).filter((p) =>
        Number.isFinite(Number(p.lat)) && Number.isFinite(Number(p.lng)));

      inst.map = new global.kakao.maps.Map(inst.mapEl, {
        center: new global.kakao.maps.LatLng(SEOUL.lat, SEOUL.lng),
        level: 13,
      });
      inst.clusterer = null;
      if (useClusterer && typeof global.kakao.maps.MarkerClusterer === 'function') {
        inst.clusterer = new global.kakao.maps.MarkerClusterer({
          map: inst.map,
          averageCenter: true,
          minLevel: 7,
          gridSize: 60,
        });
      }
      renderPoints(inst);
      inst.booted = true;
    } catch (error) {
      console.error('[YjSalesAreaMapHost]', error);
      const keyMissing = error && error.message === 'KAKAO_MAP_KEY_EMPTY';
      const body = keyMissing
        ? 'KAKAO_MAP_KEY_EMPTY'
        : `KAKAO_SDK_LOAD_FAILED: ${formatLoadError(error)}`;
      emit({ op: 'ERROR', hostId: inst.hostId, message: body });
    }
  }

  const DART_PREFIX = 'yj_sa_dart|';

  global.addEventListener('message', (event) => {
    if (event.origin !== global.location.origin) return;
    const raw = event.data;
    if (typeof raw !== 'string' || !raw.startsWith(DART_PREFIX)) return;
    try {
      const msg = JSON.parse(raw.slice(DART_PREFIX.length));
      const hostId = msg.hostId;
      if (!hostId) return;
      if (msg.op === 'CREATE') {
        const el = global.document.getElementById(hostId);
        if (el) global.YjSalesAreaMapHost.create(hostId, el);
      } else if (msg.op === 'INIT') {
        global.YjSalesAreaMapHost.init(hostId, msg);
      } else if (msg.op === 'FILTER') {
        global.YjSalesAreaMapHost.filter(hostId, msg.keyword || '');
      } else if (msg.op === 'DESTROY') {
        global.YjSalesAreaMapHost.destroy(hostId);
      }
    } catch (e) {
      console.error('[YjSalesAreaMapHost] dart message', e);
    }
  });

  global.YjSalesAreaMapHost = {
    create(hostId, container) {
      if (!container) return;
      const mapEl = global.document.createElement('div');
      mapEl.style.width = '100%';
      mapEl.style.height = '100%';
      container.appendChild(mapEl);
      const inst = {
        hostId,
        mapEl,
        map: null,
        clusterer: null,
        apiPoints: [],
        markers: [],
        overlays: [],
        activeInfoWindow: null,
        filterKeyword: '',
        booted: false,
      };
      instances.set(hostId, inst);
      emit({ op: 'READY', hostId });
    },

    init(hostId, payload) {
      const inst = instances.get(hostId);
      if (!inst) return;
      inst.filterKeyword = String(payload.keyword || '');
      bootInstance(inst, payload.points || [], payload.appKey || '');
    },

    filter(hostId, keyword) {
      const inst = instances.get(hostId);
      if (!inst || !inst.map) return;
      inst.filterKeyword = String(keyword || '');
      renderPoints(inst);
    },

    destroy(hostId) {
      const inst = instances.get(hostId);
      if (!inst) return;
      clearMapObjects(inst);
      inst.mapEl.remove();
      instances.delete(hostId);
    },
  };
})(window);
