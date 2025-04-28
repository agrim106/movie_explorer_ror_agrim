# frozen_string_literal: true
ActiveAdmin.register_page "Dashboard" do
  menu priority: 1, label: proc { I18n.t("active_admin.dashboard") }

  content title: proc { I18n.t("active_admin.dashboard") } do
    columns do
      column do
        panel "User Statistics" do
          ul do
            li "Total Users: #{User.count}"
            li "Admins: #{AdminUser.count}"
            li "Recent Users: #{User.order(created_at: :desc).limit(5).map(&:email).join(', ')}"
          end
        end
      end

      column do
        panel "Movie Statistics" do
          ul do
            li "Total Movies: #{Movie.count}"
            li "Premium Movies: #{Movie.where(premium: true).count}"
            li "Average Rating: #{Movie.average(:rating).to_f.round(2) || 0.0}"
          end
        end
      end
    end

    columns do
      column do
        panel "Users by Role" do
          # Pie chart data
          roles = User.group(:role).count
          pie_chart_data = roles.map { |role, count| { name: role || 'Unknown', y: count } }

          # Inline JavaScript for pie chart using Highcharts
          script = <<-JS
            <script src="https://code.highcharts.com/highcharts.js"></script>
            <div id="pie-chart" style="height: 300px;"></div>
            <script>
              Highcharts.chart('pie-chart', {
                chart: { type: 'pie' },
                title: { text: 'Users by Role' },
                series: [{
                  name: 'Users',
                  colorByPoint: true,
                  data: #{pie_chart_data.to_json}
                }]
              });
            </script>
          JS

          script.html_safe
        end
      end
    end
  end # content
end