# Framer Motion Animation Patterns Template

## Overview
This template provides comprehensive patterns for implementing performance-optimized animations using Framer Motion, covering page transitions, micro-interactions, gesture handling, and accessibility considerations within our NX monorepo structure.

## Performance-Optimized Animation Patterns

### Core Animation Principles
```typescript
// libs/shared/ui/src/animations/core-animations.ts
import { Variants, Transition } from 'framer-motion';

// Performance-optimized transition defaults
export const defaultTransition: Transition = {
  type: 'tween',
  ease: [0.25, 0.46, 0.45, 0.94], // Custom easing for smooth feel
  duration: 0.3
};

export const springTransition: Transition = {
  type: 'spring',
  damping: 25,
  stiffness: 300,
  mass: 0.8
};

export const fastTransition: Transition = {
  type: 'tween',
  ease: 'easeOut',
  duration: 0.15
};

// Base animation variants for common patterns
export const fadeVariants: Variants = {
  hidden: {
    opacity: 0,
    transition: defaultTransition
  },
  visible: {
    opacity: 1,
    transition: defaultTransition
  },
  exit: {
    opacity: 0,
    transition: fastTransition
  }
};

export const slideVariants: Variants = {
  hidden: {
    x: -20,
    opacity: 0,
    transition: defaultTransition
  },
  visible: {
    x: 0,
    opacity: 1,
    transition: defaultTransition
  },
  exit: {
    x: 20,
    opacity: 0,
    transition: fastTransition
  }
};

export const scaleVariants: Variants = {
  hidden: {
    scale: 0.95,
    opacity: 0,
    transition: defaultTransition
  },
  visible: {
    scale: 1,
    opacity: 1,
    transition: springTransition
  },
  exit: {
    scale: 0.95,
    opacity: 0,
    transition: fastTransition
  }
};

// Stagger animation for lists
export const staggerContainer: Variants = {
  hidden: {
    transition: {
      staggerChildren: 0.05,
      staggerDirection: -1
    }
  },
  visible: {
    transition: {
      staggerChildren: 0.1,
      delayChildren: 0.1
    }
  }
};

export const staggerItem: Variants = {
  hidden: {
    y: 20,
    opacity: 0,
    transition: defaultTransition
  },
  visible: {
    y: 0,
    opacity: 1,
    transition: defaultTransition
  }
};
```

### Reusable Animation Components
```typescript
// libs/shared/ui/src/components/animated/FadeIn.tsx
import React from 'react';
import { motion, MotionProps } from 'framer-motion';
import { fadeVariants } from '../../animations/core-animations';

interface FadeInProps extends MotionProps {
  children: React.ReactNode;
  delay?: number;
  duration?: number;
  className?: string;
}

export const FadeIn: React.FC<FadeInProps> = ({
  children,
  delay = 0,
  duration = 0.3,
  className,
  ...motionProps
}) => {
  const customVariants = {
    ...fadeVariants,
    visible: {
      ...fadeVariants.visible,
      transition: {
        ...fadeVariants.visible.transition,
        delay,
        duration
      }
    }
  };

  return (
    <motion.div
      variants={customVariants}
      initial="hidden"
      animate="visible"
      exit="exit"
      className={className}
      {...motionProps}
    >
      {children}
    </motion.div>
  );
};
```

```typescript
// libs/shared/ui/src/components/animated/SlideIn.tsx
import React from 'react';
import { motion, MotionProps } from 'framer-motion';
import { slideVariants } from '../../animations/core-animations';

interface SlideInProps extends MotionProps {
  children: React.ReactNode;
  direction?: 'left' | 'right' | 'up' | 'down';
  distance?: number;
  delay?: number;
  className?: string;
}

export const SlideIn: React.FC<SlideInProps> = ({
  children,
  direction = 'left',
  distance = 20,
  delay = 0,
  className,
  ...motionProps
}) => {
  const getDirectionOffset = () => {
    switch (direction) {
      case 'left': return { x: -distance, y: 0 };
      case 'right': return { x: distance, y: 0 };
      case 'up': return { x: 0, y: -distance };
      case 'down': return { x: 0, y: distance };
      default: return { x: -distance, y: 0 };
    }
  };

  const offset = getDirectionOffset();
  const customVariants = {
    hidden: {
      ...offset,
      opacity: 0
    },
    visible: {
      x: 0,
      y: 0,
      opacity: 1,
      transition: {
        type: 'spring',
        damping: 25,
        stiffness: 300,
        delay
      }
    },
    exit: {
      ...offset,
      opacity: 0,
      transition: {
        duration: 0.15
      }
    }
  };

  return (
    <motion.div
      variants={customVariants}
      initial="hidden"
      animate="visible"
      exit="exit"
      className={className}
      {...motionProps}
    >
      {children}
    </motion.div>
  );
};
```

## Page Transitions

### Layout Animation Provider
```typescript
// libs/shared/ui/src/components/layout/AnimatedLayout.tsx
import React from 'react';
import { motion, AnimatePresence, LayoutGroup } from 'framer-motion';
import { useRouter } from 'next/router';

interface AnimatedLayoutProps {
  children: React.ReactNode;
}

const pageVariants = {
  initial: {
    opacity: 0,
    x: -20,
    scale: 0.98
  },
  in: {
    opacity: 1,
    x: 0,
    scale: 1,
    transition: {
      duration: 0.4,
      ease: [0.25, 0.46, 0.45, 0.94]
    }
  },
  out: {
    opacity: 0,
    x: 20,
    scale: 0.98,
    transition: {
      duration: 0.3,
      ease: [0.55, 0.085, 0.68, 0.53]
    }
  }
};

export const AnimatedLayout: React.FC<AnimatedLayoutProps> = ({ children }) => {
  const router = useRouter();

  return (
    <LayoutGroup>
      <AnimatePresence mode="wait" initial={false}>
        <motion.div
          key={router.pathname}
          variants={pageVariants}
          initial="initial"
          animate="in"
          exit="out"
          className="min-h-screen"
        >
          {children}
        </motion.div>
      </AnimatePresence>
    </LayoutGroup>
  );
};
```

### Route-Specific Transitions
```typescript
// libs/shared/ui/src/components/transitions/RouteTransition.tsx
import React from 'react';
import { motion } from 'framer-motion';

interface RouteTransitionProps {
  children: React.ReactNode;
  transitionKey: string;
  variant?: 'slide' | 'fade' | 'scale';
}

const transitionVariants = {
  slide: {
    initial: { x: 300, opacity: 0 },
    animate: { x: 0, opacity: 1 },
    exit: { x: -300, opacity: 0 }
  },
  fade: {
    initial: { opacity: 0 },
    animate: { opacity: 1 },
    exit: { opacity: 0 }
  },
  scale: {
    initial: { scale: 0.8, opacity: 0 },
    animate: { scale: 1, opacity: 1 },
    exit: { scale: 1.2, opacity: 0 }
  }
};

export const RouteTransition: React.FC<RouteTransitionProps> = ({
  children,
  transitionKey,
  variant = 'slide'
}) => {
  const variants = transitionVariants[variant];

  return (
    <motion.div
      key={transitionKey}
      initial="initial"
      animate="animate"
      exit="exit"
      variants={variants}
      transition={{
        type: 'tween',
        ease: 'anticipate',
        duration: 0.5
      }}
    >
      {children}
    </motion.div>
  );
};
```

## Micro-Interactions

### Interactive Button Component
```typescript
// libs/shared/ui/src/components/interactive/AnimatedButton.tsx
import React from 'react';
import { motion, MotionProps } from 'framer-motion';
import { cn } from '../../utils/cn';

interface AnimatedButtonProps extends MotionProps {
  children: React.ReactNode;
  variant?: 'primary' | 'secondary' | 'ghost';
  size?: 'sm' | 'md' | 'lg';
  disabled?: boolean;
  loading?: boolean;
  onClick?: () => void;
  className?: string;
}

export const AnimatedButton: React.FC<AnimatedButtonProps> = ({
  children,
  variant = 'primary',
  size = 'md',
  disabled = false,
  loading = false,
  onClick,
  className,
  ...motionProps
}) => {
  const baseClasses = 'relative inline-flex items-center justify-center font-medium rounded-lg transition-colors focus:outline-none focus:ring-2 focus:ring-offset-2';
  
  const variantClasses = {
    primary: 'bg-blue-600 text-white hover:bg-blue-700 focus:ring-blue-500',
    secondary: 'bg-gray-200 text-gray-900 hover:bg-gray-300 focus:ring-gray-500',
    ghost: 'text-gray-700 hover:bg-gray-100 focus:ring-gray-500'
  };

  const sizeClasses = {
    sm: 'px-3 py-1.5 text-sm',
    md: 'px-4 py-2 text-base',
    lg: 'px-6 py-3 text-lg'
  };

  return (
    <motion.button
      className={cn(
        baseClasses,
        variantClasses[variant],
        sizeClasses[size],
        disabled && 'opacity-50 cursor-not-allowed',
        className
      )}
      disabled={disabled || loading}
      onClick={onClick}
      whileHover={!disabled ? { scale: 1.02 } : {}}
      whileTap={!disabled ? { scale: 0.98 } : {}}
      transition={{
        type: 'spring',
        stiffness: 400,
        damping: 17
      }}
      {...motionProps}
    >
      <AnimatePresence mode="wait">
        {loading ? (
          <motion.div
            key="loading"
            initial={{ opacity: 0 }}
            animate={{ opacity: 1 }}
            exit={{ opacity: 0 }}
            className="flex items-center"
          >
            <motion.div
              className="w-4 h-4 border-2 border-current border-t-transparent rounded-full mr-2"
              animate={{ rotate: 360 }}
              transition={{
                duration: 1,
                repeat: Infinity,
                ease: 'linear'
              }}
            />
            Loading...
          </motion.div>
        ) : (
          <motion.span
            key="content"
            initial={{ opacity: 0 }}
            animate={{ opacity: 1 }}
            exit={{ opacity: 0 }}
          >
            {children}
          </motion.span>
        )}
      </AnimatePresence>
    </motion.button>
  );
};
```

### Card Hover Effects
```typescript
// libs/shared/ui/src/components/interactive/AnimatedCard.tsx
import React from 'react';
import { motion } from 'framer-motion';
import { cn } from '../../utils/cn';

interface AnimatedCardProps {
  children: React.ReactNode;
  className?: string;
  hoverEffect?: 'lift' | 'glow' | 'tilt';
  clickable?: boolean;
  onClick?: () => void;
}

export const AnimatedCard: React.FC<AnimatedCardProps> = ({
  children,
  className,
  hoverEffect = 'lift',
  clickable = false,
  onClick
}) => {
  const hoverVariants = {
    lift: {
      y: -8,
      boxShadow: '0 20px 25px -5px rgba(0, 0, 0, 0.1), 0 10px 10px -5px rgba(0, 0, 0, 0.04)'
    },
    glow: {
      boxShadow: '0 0 20px rgba(59, 130, 246, 0.3)'
    },
    tilt: {
      rotateY: 5,
      rotateX: 5,
      scale: 1.02
    }
  };

  return (
    <motion.div
      className={cn(
        'bg-white rounded-lg shadow-md overflow-hidden',
        clickable && 'cursor-pointer',
        className
      )}
      whileHover={hoverVariants[hoverEffect]}
      whileTap={clickable ? { scale: 0.98 } : {}}
      transition={{
        type: 'spring',
        stiffness: 300,
        damping: 20
      }}
      onClick={onClick}
      style={{ transformStyle: 'preserve-3d' }}
    >
      {children}
    </motion.div>
  );
};
```

## Gesture Handling

### Swipeable Component
```typescript
// libs/shared/ui/src/components/gestures/SwipeableCard.tsx
import React, { useState } from 'react';
import { motion, PanInfo, useMotionValue, useTransform } from 'framer-motion';

interface SwipeableCardProps {
  children: React.ReactNode;
  onSwipeLeft?: () => void;
  onSwipeRight?: () => void;
  onSwipeUp?: () => void;
  onSwipeDown?: () => void;
  swipeThreshold?: number;
  className?: string;
}

export const SwipeableCard: React.FC<SwipeableCardProps> = ({
  children,
  onSwipeLeft,
  onSwipeRight,
  onSwipeUp,
  onSwipeDown,
  swipeThreshold = 100,
  className
}) => {
  const [isExiting, setIsExiting] = useState(false);
  const x = useMotionValue(0);
  const y = useMotionValue(0);

  const rotateZ = useTransform(x, [-200, 200], [-15, 15]);
  const opacity = useTransform(x, [-200, -100, 0, 100, 200], [0, 1, 1, 1, 0]);

  const handleDragEnd = (event: MouseEvent | TouchEvent | PointerEvent, info: PanInfo) => {
    const { offset, velocity } = info;

    if (Math.abs(offset.x) > swipeThreshold || Math.abs(velocity.x) > 500) {
      setIsExiting(true);

      if (offset.x > 0 && onSwipeRight) {
        onSwipeRight();
      } else if (offset.x < 0 && onSwipeLeft) {
        onSwipeLeft();
      }
    } else if (Math.abs(offset.y) > swipeThreshold || Math.abs(velocity.y) > 500) {
      setIsExiting(true);

      if (offset.y > 0 && onSwipeDown) {
        onSwipeDown();
      } else if (offset.y < 0 && onSwipeUp) {
        onSwipeUp();
      }
    }
  };

  if (isExiting) {
    return null;
  }

  return (
    <motion.div
      className={className}
      style={{ x, y, rotateZ, opacity }}
      drag
      dragConstraints={{ left: 0, right: 0, top: 0, bottom: 0 }}
      dragElastic={0.2}
      onDragEnd={handleDragEnd}
      whileDrag={{ scale: 1.05 }}
      transition={{
        type: 'spring',
        stiffness: 300,
        damping: 20
      }}
    >
      {children}
    </motion.div>
  );
};
```

### Draggable List Item
```typescript
// libs/shared/ui/src/components/gestures/DraggableListItem.tsx
import React from 'react';
import { motion, Reorder } from 'framer-motion';

interface DraggableListItemProps {
  item: any;
  children: React.ReactNode;
  className?: string;
}

export const DraggableListItem: React.FC<DraggableListItemProps> = ({
  item,
  children,
  className
}) => {
  return (
    <Reorder.Item
      value={item}
      className={className}
      whileDrag={{
        scale: 1.02,
        boxShadow: '0 10px 15px -3px rgba(0, 0, 0, 0.1), 0 4px 6px -2px rgba(0, 0, 0, 0.05)',
        zIndex: 10
      }}
      transition={{
        type: 'spring',
        stiffness: 300,
        damping: 20
      }}
    >
      {children}
    </Reorder.Item>
  );
};
```

## Accessibility Considerations

### Reduced Motion Support
```typescript
// libs/shared/ui/src/hooks/useReducedMotion.ts
import { useEffect, useState } from 'react';

export const useReducedMotion = (): boolean => {
  const [prefersReducedMotion, setPrefersReducedMotion] = useState(false);

  useEffect(() => {
    const mediaQuery = window.matchMedia('(prefers-reduced-motion: reduce)');
    setPrefersReducedMotion(mediaQuery.matches);

    const handleChange = (event: MediaQueryListEvent) => {
      setPrefersReducedMotion(event.matches);
    };

    mediaQuery.addEventListener('change', handleChange);
    return () => mediaQuery.removeEventListener('change', handleChange);
  }, []);

  return prefersReducedMotion;
};
```

### Accessible Animation Wrapper
```typescript
// libs/shared/ui/src/components/accessibility/AccessibleMotion.tsx
import React from 'react';
import { motion, MotionProps } from 'framer-motion';
import { useReducedMotion } from '../../hooks/useReducedMotion';

interface AccessibleMotionProps extends MotionProps {
  children: React.ReactNode;
  reduceMotion?: boolean;
  fallbackComponent?: React.ComponentType<any>;
}

export const AccessibleMotion: React.FC<AccessibleMotionProps> = ({
  children,
  reduceMotion,
  fallbackComponent: FallbackComponent = 'div',
  ...motionProps
}) => {
  const prefersReducedMotion = useReducedMotion();
  const shouldReduceMotion = reduceMotion ?? prefersReducedMotion;

  if (shouldReduceMotion) {
    return <FallbackComponent>{children}</FallbackComponent>;
  }

  return <motion.div {...motionProps}>{children}</motion.div>;
};
```

## Best Practices

### Performance Optimization
- **Use transform and opacity**: Stick to animating transform and opacity properties for 60fps performance
- **Avoid layout animations**: Minimize animations that trigger layout recalculations
- **Use will-change**: Apply will-change CSS property for complex animations
- **Optimize for mobile**: Test animations on lower-end devices

### Animation Guidelines
- **Duration Standards**:
  - Micro-interactions: 100-200ms
  - UI transitions: 200-500ms
  - Page transitions: 300-600ms
- **Easing Functions**: Use natural easing curves for organic feel
- **Stagger Animations**: Use stagger for list animations to create flow
- **Exit Animations**: Always provide exit animations for smooth transitions

### Accessibility Standards
- **Respect prefers-reduced-motion**: Always check and respect user motion preferences
- **Provide alternatives**: Offer non-animated alternatives for critical interactions
- **Focus management**: Ensure focus is properly managed during animations
- **Screen reader compatibility**: Test with screen readers to ensure animations don't interfere

### Code Organization
- **Reusable variants**: Create reusable animation variants for consistency
- **Component composition**: Build complex animations from simple, composable components
- **Performance monitoring**: Monitor animation performance in production
- **Testing**: Include animation testing in your test suite

This Framer Motion animation patterns template provides a comprehensive foundation for creating performant, accessible animations within our NX monorepo structure.

