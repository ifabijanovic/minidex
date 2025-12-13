"use client";

import { isEqual } from "lodash";
import { useEffect, useState } from "react";

type FormValues = Record<string, unknown>;

type LookupOption = { id: string; name: string };

type FormChangeOptions<T extends FormValues> = {
  initialValues: T;
};

type FormChangeResult<T extends FormValues> = {
  values: T;
  setValue: <K extends keyof T>(key: K, value: T[K]) => void;
  hasChanges: boolean;
  getCreatePayload: () => T;
  getUpdatePayload: () => Partial<T>;
};

export function useFormChanges<T extends FormValues>({
  initialValues,
}: FormChangeOptions<T>): FormChangeResult<T> {
  const [values, setValues] = useState<T>(initialValues);
  const [changedFields, setChangedFields] = useState<Set<keyof T>>(new Set());

  // Track changes when values change
  useEffect(() => {
    const changes = new Set<keyof T>();
    (Object.keys(values) as (keyof T)[]).forEach((key) => {
      if (!isEqual(values[key], initialValues[key])) {
        changes.add(key);
      }
    });
    // eslint-disable-next-line react-hooks/set-state-in-effect
    setChangedFields(changes);
  }, [values, initialValues]);

  const setValue = <K extends keyof T>(key: K, value: T[K]) => {
    setValues((prev) => ({ ...prev, [key]: value }));
  };

  const getCreatePayload = (): T => values;

  const getUpdatePayload = (): Partial<T> => {
    const payload: Partial<T> = {};

    changedFields.forEach((field) => {
      payload[field] = values[field];
    });

    return payload;
  };

  const hasChanges = changedFields.size > 0;

  return {
    values,
    setValue,
    hasChanges,
    getCreatePayload,
    getUpdatePayload,
  };
}

// Hook for managing lookup dropdown state with display values
export function useLookupField({
  initialId,
  initialName,
  onIdChange,
}: {
  initialId?: string | null;
  initialName?: string | null;
  onIdChange: (id: string | null) => void;
}) {
  const [selectedOption, setSelectedOption] = useState<LookupOption | null>(
    initialId && initialName ? { id: initialId, name: initialName } : null,
  );

  const handleChange = (option: LookupOption | null) => {
    setSelectedOption(option);
    onIdChange(option?.id || null);
  };

  return {
    value: selectedOption,
    onChange: handleChange,
  };
}
