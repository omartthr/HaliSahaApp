"use client";

import React, { useEffect, useState } from "react";
import dynamic from "next/dynamic";

// Since we use window/document in leaflet, we must import it dynamically with ssr: false
// But for MapContainer itself, we can dynamically import the component that renders it.
const MapComponent = dynamic(
  () => import("./LocationPickerMapInner"),
  { ssr: false, loading: () => <div className="w-full h-[250px] bg-gray-100 rounded-xl animate-pulse flex items-center justify-center text-sm text-gray-500">Harita yükleniyor...</div> }
);

interface LocationPickerProps {
  position: [number, number];
  onChange: (pos: [number, number]) => void;
}

const LocationPickerMap = (props: LocationPickerProps) => {
  return <MapComponent {...props} />;
};

export default LocationPickerMap;
