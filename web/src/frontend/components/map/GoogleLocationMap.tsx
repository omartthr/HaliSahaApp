"use client";

import React, { useEffect } from "react";
import dynamic from "next/dynamic";

const MapComponent = dynamic(
  () => import("./GoogleLocationMapInner"),
  { ssr: false, loading: () => <div className="w-full h-full bg-gray-100 rounded-xl animate-pulse flex items-center justify-center text-sm text-gray-500">Google Haritalar yükleniyor...</div> }
);

interface GoogleLocationMapProps {
  position: [number, number];
  onChange?: (pos: [number, number]) => void;
  readOnly?: boolean;
}

export default function GoogleLocationMap(props: GoogleLocationMapProps) {
  return <MapComponent {...props} />;
}
