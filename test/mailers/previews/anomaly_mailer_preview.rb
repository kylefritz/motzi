# Preview all emails at http://localhost:3000/rails/mailers/anomaly_mailer
class AnomalyMailerPreview < ApplicationMailerPreview
  def anomaly_report
    analysis = AnomalyAnalysis.last
    return missing("No AnomalyAnalysis records. Run an analysis first.") unless analysis

    AnomalyMailer.with(analysis: analysis).anomaly_report
  end
end
