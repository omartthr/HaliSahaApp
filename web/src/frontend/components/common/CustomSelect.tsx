"use client";
import React, { useState, useRef, useEffect } from "react";
import { createPortal } from "react-dom";
import { ChevronDown, Check } from "lucide-react";

interface Option {
  value: string | number;
  label: string;
}

interface CustomSelectProps {
  options: Option[];
  value: string | number;
  onChange: (value: string) => void;
  placeholder?: string;
  className?: string;
  icon?: React.ReactNode;
}

export default function CustomSelect({
  options,
  value,
  onChange,
  placeholder = "Seçiniz...",
  className = "",
  icon
}: CustomSelectProps) {
  const [isOpen, setIsOpen] = useState(false);
  const selectRef = useRef<HTMLDivElement>(null);
  const [dropdownStyle, setDropdownStyle] = useState<React.CSSProperties>({});
  const [mounted, setMounted] = useState(false);

  const selectedOption = options.find((opt) => opt.value === value);

  useEffect(() => {
    setMounted(true);
  }, []);

  const updatePosition = () => {
    if (selectRef.current) {
      const rect = selectRef.current.getBoundingClientRect();
      setDropdownStyle({
        position: "fixed",
        top: rect.bottom + 8,
        left: rect.left,
        width: rect.width,
        zIndex: 99999,
      });
    }
  };

  useEffect(() => {
    if (isOpen) {
      updatePosition();
      window.addEventListener("scroll", updatePosition, true);
      window.addEventListener("resize", updatePosition);
    } else {
      window.removeEventListener("scroll", updatePosition, true);
      window.removeEventListener("resize", updatePosition);
    }
    return () => {
      window.removeEventListener("scroll", updatePosition, true);
      window.removeEventListener("resize", updatePosition);
    };
  }, [isOpen]);

  // Close on outside click
  useEffect(() => {
    function handleClickOutside(event: MouseEvent) {
      // If clicking inside the trigger button
      if (selectRef.current && selectRef.current.contains(event.target as Node)) {
        return;
      }
      // If clicking inside the portal dropdown
      const portalEl = document.getElementById("custom-select-portal");
      if (portalEl && portalEl.contains(event.target as Node)) {
        return;
      }
      setIsOpen(false);
    }
    if (isOpen) {
      document.addEventListener("mousedown", handleClickOutside);
    }
    return () => document.removeEventListener("mousedown", handleClickOutside);
  }, [isOpen]);

  const renderDropdown = () => (
    <div
      id="custom-select-portal"
      style={{
        ...dropdownStyle,
        background: "#ffffff",
        borderRadius: 16,
        boxShadow: "0 12px 32px rgba(0,0,0,0.12), 0 0 0 1px rgba(0,0,0,0.05)",
        overflow: "hidden",
        opacity: isOpen ? 1 : 0,
        visibility: isOpen ? "visible" : "hidden",
        transform: isOpen ? "translateY(0) scale(1)" : "translateY(-10px) scale(0.95)",
        transition: "all 0.25s cubic-bezier(0.16, 1, 0.3, 1)",
        transformOrigin: "top center",
      }}
    >
      <div style={{ maxHeight: 280, overflowY: "auto", padding: "8px" }}>
        {options.map((option) => {
          const isSelected = option.value === value;
          return (
            <div
              key={option.value}
              onClick={() => {
                onChange(String(option.value));
                setIsOpen(false);
              }}
              style={{
                padding: "12px 16px",
                borderRadius: 12,
                display: "flex",
                alignItems: "center",
                justifyContent: "space-between",
                cursor: "pointer",
                background: isSelected ? "rgba(46, 125, 50, 0.08)" : "transparent",
                color: isSelected ? "#2E7D32" : "#4b5563",
                fontWeight: isSelected ? 700 : 500,
                fontSize: 14,
                transition: "all 0.15s ease",
              }}
              onMouseEnter={(e) => {
                if (!isSelected) {
                  (e.currentTarget as HTMLDivElement).style.background = "rgba(0,0,0,0.03)";
                  (e.currentTarget as HTMLDivElement).style.color = "#111827";
                }
              }}
              onMouseLeave={(e) => {
                if (!isSelected) {
                  (e.currentTarget as HTMLDivElement).style.background = "transparent";
                  (e.currentTarget as HTMLDivElement).style.color = "#4b5563";
                }
              }}
            >
              {option.label}
              {isSelected && <Check size={16} color="#2E7D32" />}
            </div>
          );
        })}
      </div>
    </div>
  );

  return (
    <>
      <div 
        ref={selectRef} 
        className={`custom-select-wrapper ${className}`}
        style={{ position: "relative", width: "100%", userSelect: "none" }}
      >
        <div
          onClick={() => setIsOpen(!isOpen)}
          style={{
            display: "flex",
            alignItems: "center",
            justifyContent: "space-between",
            padding: "14px 16px",
            background: "rgba(255, 255, 255, 0.9)",
            border: isOpen ? "2px solid #2E7D32" : "1px solid rgba(0,0,0,0.1)",
            borderRadius: 16,
            cursor: "pointer",
            transition: "all 0.2s ease",
            boxShadow: isOpen ? "0 8px 24px rgba(46, 125, 50, 0.15)" : "0 2px 8px rgba(0,0,0,0.02)",
          }}
        >
          <div style={{ display: "flex", alignItems: "center", gap: 10, color: selectedOption ? "#111827" : "#9ca3af", fontWeight: selectedOption ? 600 : 400, fontSize: 15 }}>
            {icon && <span style={{ color: selectedOption ? "#2E7D32" : "#9ca3af" }}>{icon}</span>}
            {selectedOption ? selectedOption.label : placeholder}
          </div>
          <ChevronDown 
            size={18} 
            color={isOpen ? "#2E7D32" : "#6b7280"} 
            style={{ 
              transform: isOpen ? "rotate(180deg)" : "rotate(0)", 
              transition: "transform 0.3s cubic-bezier(0.175, 0.885, 0.32, 1.275)" 
            }} 
          />
        </div>
      </div>
      {mounted && createPortal(renderDropdown(), document.body)}
    </>
  );
}
