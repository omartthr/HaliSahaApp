"use client";

import dynamic from "next/dynamic";
import React, { useState } from "react";
import FieldDetailsPanel from "./FieldDetailsPanel";

const Map = dynamic(() => import("./FieldMap"), { 
  ssr: false,
  loading: () => <div className="h-full w-full bg-gray-100 animate-pulse flex items-center justify-center text-gray-400">Harita Yükleniyor...</div>
});

const MapSection = () => {
  const [selectedField, setSelectedField] = useState<any>(null);

  return (
    <div id="map" className="relative h-[600px] w-full bg-gray-100 border-y border-gray-200 overflow-hidden">
      <Map onSelectField={setSelectedField} />
      {selectedField && (
        <FieldDetailsPanel 
          field={selectedField} 
          onClose={() => setSelectedField(null)} 
        />
      )}
    </div>
  );
};

export default MapSection;
