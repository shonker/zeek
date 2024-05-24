// See the file "COPYING" in the main distribution directory for copyright.

#pragma once

#include <prometheus/family.h>
#include <prometheus/histogram.h>
#include <cstdint>
#include <initializer_list>
#include <memory>

#include "zeek/Span.h"
#include "zeek/telemetry/MetricFamily.h"
#include "zeek/telemetry/Utils.h"
#include "zeek/telemetry/telemetry.bif.h"

namespace zeek::telemetry {

class Histogram {
public:
    static inline const char* OpaqueName = "HistogramMetricVal";

    using Handle = prometheus::Histogram;
    using FamilyType = prometheus::Family<Handle>;

    explicit Histogram(FamilyType* family, const prometheus::Labels& labels,
                       prometheus::Histogram::BucketBoundaries bounds) noexcept;

    /**
     * Increments all buckets with an upper bound less than or equal to @p value
     * by one and adds @p value to the total sum of all observed values.
     */
    void Observe(double value) noexcept { handle.Observe(value); }

    /// @return The sum of all observed values.
    double Sum() const noexcept;

    bool operator==(const Histogram& rhs) const noexcept { return &handle == &rhs.handle; }
    bool operator!=(const Histogram& rhs) const noexcept { return &handle != &rhs.handle; }

    bool CompareLabels(const prometheus::Labels& lbls) const { return labels == lbls; }

private:
    Handle& handle;
    prometheus::Labels labels;
};

class HistogramFamily : public MetricFamily, public std::enable_shared_from_this<HistogramFamily> {
public:
    static inline const char* OpaqueName = "HistogramMetricFamilyVal";

    HistogramFamily(prometheus::Family<prometheus::Histogram>* family, Span<const double> bounds,
                    Span<const std::string_view> labels);

    /**
     * Returns the metrics handle for given labels, creating a new instance
     * lazily if necessary.
     */
    std::shared_ptr<Histogram> GetOrAdd(Span<const LabelView> labels);

    /**
     * @copydoc GetOrAdd
     */
    std::shared_ptr<Histogram> GetOrAdd(std::initializer_list<LabelView> labels);

    zeek_int_t MetricType() const noexcept override { return BifEnum::Telemetry::MetricType::HISTOGRAM; }

private:
    prometheus::Family<prometheus::Histogram>* family;
    prometheus::Histogram::BucketBoundaries boundaries;
    std::vector<std::shared_ptr<Histogram>> histograms;
};

} // namespace zeek::telemetry
