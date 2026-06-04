"use client";

import React from "react";
import Link from "next/link";
import { usePathname } from "next/navigation";
import { Home, Users, PlusCircle, User } from "lucide-react";
import { useAuth } from "@/frontend/context/AuthContext";

const navItems = [
  { label: "Keşfet", Icon: Home, href: "/", requiresAuth: false },
  { label: "Gruplar", Icon: Users, href: "/groups", requiresAuth: false },
  { label: "Maç Kur", Icon: PlusCircle, href: "/groups/create", requiresAuth: false },
  { label: "Profil", Icon: User, href: "/profile", requiresAuth: true },
];

export default function MobileBottomNav() {
  const pathname = usePathname();
  const { user, isAdmin } = useAuth();

  // Admin panelinde, giriş/kayıt ekranlarında ve admin kullanıcıları için gizle
  if (
    isAdmin ||
    pathname.startsWith("/admin") ||
    pathname === "/login" ||
    pathname === "/register"
  ) {
    return null;
  }

  return (
    <nav className="mobile-bottom-nav" aria-label="Mobil navigasyon">
      {navItems.map(({ label, Icon, href, requiresAuth }) => {
        const targetHref = requiresAuth && !user ? "/login" : href;
        const isActive = pathname === href || (href !== "/" && pathname.startsWith(href));

        return (
          <Link
            key={label}
            href={targetHref}
            className={`mob-nav-item${isActive ? " mob-nav-item--active" : ""}`}
            aria-label={label}
          >
            <div className="mob-nav-icon-wrap">
              <Icon
                size={22}
                strokeWidth={isActive ? 2.5 : 1.8}
                className="mob-nav-icon"
              />
              {isActive && <span className="mob-nav-dot" />}
            </div>
            <span className="mob-nav-label">{label}</span>
          </Link>
        );
      })}
    </nav>
  );
}
