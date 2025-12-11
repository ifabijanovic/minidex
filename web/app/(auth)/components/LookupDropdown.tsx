"use client";

import { Autocomplete, CircularProgress, TextField } from "@mui/material";
import { useDebounce } from "@uidotdev/usehooks";
import { useEffect, useMemo, useState } from "react";

export type LookupOption = { id: string; name: string };

type LookupDropdownProps = {
  label: string;
  placeholder: string;
  value: LookupOption | null;
  onChange: (option: LookupOption | null) => void;
  fetcher: (query: string) => Promise<LookupOption[]>;
  disabled?: boolean;
  excludeIds?: string[];
};

export function LookupDropdown({
  label,
  placeholder,
  value,
  onChange,
  fetcher,
  disabled,
  excludeIds,
}: LookupDropdownProps) {
  const [search, setSearch] = useState(value?.name ?? "");
  const [options, setOptions] = useState<LookupOption[]>([]);
  const [loading, setLoading] = useState(false);
  const debouncedSearch = useDebounce(search, 300);

  /* eslint-disable react-hooks/set-state-in-effect */
  useEffect(() => {
    const q = debouncedSearch.trim();
    const shouldFetch = q.length === 0 || q.length >= 3;
    if (!shouldFetch) {
      return;
    }

    let cancelled = false;
    setLoading(true);
    fetcher(q)
      .then((items) => {
        if (!cancelled) {
          const filtered = items.filter(
            (item) =>
              !excludeIds?.includes(item.id) &&
              (!value || item.id !== value.id),
          );
          setOptions(filtered);
        }
      })
      .catch(() => {
        if (!cancelled) setOptions([]);
      })
      .finally(() => {
        if (!cancelled) setLoading(false);
      });

    return () => {
      cancelled = true;
    };
  }, [debouncedSearch, excludeIds, fetcher, value]);
  /* eslint-enable react-hooks/set-state-in-effect */

  const mergedOptions = useMemo(() => {
    if (
      value &&
      !excludeIds?.includes(value.id) &&
      !options.some((o) => o.id === value.id)
    ) {
      return [{ id: value.id, name: value.name }, ...options];
    }
    return options;
  }, [excludeIds, options, value]);

  return (
    <Autocomplete
      options={mergedOptions}
      getOptionLabel={(option) => option.name}
      loading={loading}
      value={
        value ? (mergedOptions.find((o) => o.id === value.id) ?? value) : null
      }
      onChange={(_, option) => {
        onChange(option ?? null);
        setSearch(option?.name ?? "");
      }}
      inputValue={search}
      onInputChange={(_, val) => setSearch(val)}
      isOptionEqualToValue={(option, val) => option.id === val.id}
      disabled={disabled}
      renderInput={(params) => (
        <TextField
          {...params}
          label={label}
          placeholder={placeholder}
          InputLabelProps={{ shrink: true, required: false }}
          InputProps={{
            ...params.InputProps,
            endAdornment: (
              <>
                {loading ? (
                  <CircularProgress color="inherit" size={20} />
                ) : null}
                {params.InputProps.endAdornment}
              </>
            ),
          }}
        />
      )}
    />
  );
}
