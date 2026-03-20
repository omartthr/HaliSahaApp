"use client";

import React from "react";

type StarBorderProps = {
  children: React.ReactNode;
  className?: string;
  color?: string;
  speed?: string;
  thickness?: number;
};

export default function StarBorder({
  children,
  className,
  color = "rgba(255,255,255,0.95)",
  speed = "5s",
  thickness = 1,
}: StarBorderProps) {
  const style = {
    ["--star-border-color" as string]: color,
    ["--star-border-speed" as string]: speed,
    ["--star-border-thickness" as string]: `${thickness}px`,
  } as React.CSSProperties;

  return (
    <span className={`star-border-shell${className ? ` ${className}` : ""}`} style={style}>
      <span className="star-border-inner">{children}</span>
    </span>
  );
}